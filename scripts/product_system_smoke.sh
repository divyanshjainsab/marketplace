#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BACKEND_BASE="${BACKEND_BASE:-http://localhost:3001}"
SSO_BASE="${SSO_BASE:-http://localhost:3003}"
ADMINFRONT_BASE="${ADMINFRONT_BASE:-http://localhost:3000}"
ADMINFRONT_B_BASE="${ADMINFRONT_B_BASE:-http://localhost:3000}"
ADMINFRONT_B_PORT="${ADMINFRONT_B_PORT:-3000}"
PASSWORD="${SEED_PASSWORD:-Password123!}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

function json_get() {
  python3 -c 'import json,sys
path=sys.argv[1]
obj=json.load(sys.stdin)
cur=obj
for part in path.split("."):
  cur = cur[int(part)] if part.isdigit() else cur[part]
print(cur if cur is not None else "")' "$@"
}

function login_via_oidc() {
  local email="$1"
  local origin_host="$2"
  local origin_port="$3"
  local jar="$4"
  local frontend_base="${5:-$ADMINFRONT_BASE}"

  rm -f "$jar"

  local start_headers="$tmpdir/start_headers.txt"
  curl -sS -D "$start_headers" -o /dev/null \
    -c "$jar" -b "$jar" \
    -H "Referer: ${frontend_base}/login" \
    "${BACKEND_BASE}/auth/oidc/start/admin?return_to=%2Fdashboard&origin_host=${origin_host}&origin_port=${origin_port}&origin_scheme=http"

  local authorize_url
  authorize_url="$(awk -F': ' 'tolower($1)=="location"{print $2}' "$start_headers" | tr -d '\r' | tail -n1)"
  if [[ -z "$authorize_url" ]]; then
    echo "Missing authorize redirect from backend" >&2
    return 1
  fi

  curl -sS -D /dev/null -o /dev/null \
    -c "$jar" -b "$jar" \
    "$authorize_url"

  local login_json
  login_json="$(
    curl -sS \
      -c "$jar" -b "$jar" \
      -H "Accept: application/json" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -X POST "${SSO_BASE}/login.json" \
      --data-urlencode "user[email]=${email}" \
      --data-urlencode "user[password]=${PASSWORD}" || true
  )"

  local redirect_url
  redirect_url="$(printf "%s" "$login_json" | json_get "redirect_url" 2>/dev/null || true)"
  if [[ -z "$redirect_url" || "$redirect_url" == "None" ]]; then
    echo "Login failed for ${email}. Raw response:" >&2
    echo "$login_json" >&2
    return 1
  fi

  curl -sS -D /dev/null -o /dev/null \
    -c "$jar" -b "$jar" \
    "$redirect_url"

  if ! grep -q "mp_access" "$jar"; then
    echo "Backend callback did not establish an admin session for ${email}" >&2
    return 1
  fi
}

function fetch_json() {
  local url="$1"
  local jar="$2"
  local tenant_hostport="$3"
  curl -sS \
    -b "$jar" -c "$jar" \
    -H "Accept: application/json" \
    -H "X-Forwarded-Host: ${tenant_hostport}" \
    -H "X-Forwarded-Port: ${tenant_hostport##*:}" \
    "$url"
}

function write_json() {
  local method="$1"
  local url="$2"
  local jar="$3"
  local payload_file="$4"
  local tenant_hostport="$5"

  curl -sS \
    -b "$jar" -c "$jar" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: ${tenant_hostport}" \
    -H "X-Forwarded-Port: ${tenant_hostport##*:}" \
    -X "$method" "$url" \
    --data @"$payload_file"
}

function write_json_with_code() {
  local method="$1"
  local url="$2"
  local jar="$3"
  local payload_file="$4"
  local tenant_hostport="$5"
  local out_file="$6"

  curl -sS -o "$out_file" -w "%{http_code}" \
    -b "$jar" -c "$jar" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: ${tenant_hostport}" \
    -H "X-Forwarded-Port: ${tenant_hostport##*:}" \
    -X "$method" "$url" \
    --data @"$payload_file"
}

function assert_equals() {
  local actual="$1"
  local expected="$2"
  local label="${3:-value}"
  if [[ "$actual" != "$expected" ]]; then
    echo "Expected ${label}=${expected}, got ${actual}" >&2
    return 1
  fi
}

function assert_not_equals() {
  local actual="$1"
  local expected="$2"
  local label="${3:-value}"
  if [[ "$actual" == "$expected" ]]; then
    echo "Expected ${label} to differ from ${expected}" >&2
    return 1
  fi
}

echo "== Product system smoke test (global products, variant attributes, tenant inventory) =="
echo "Backend: ${BACKEND_BASE}"
echo "SSO: ${SSO_BASE}"
echo "Adminfront: ${ADMINFRONT_BASE}"
echo

jar_admin_a="$tmpdir/adminA.cookies"
jar_admin_b="$tmpdir/adminB.cookies"

login_via_oidc "adminA@test.com" "localhost" "3000" "$jar_admin_a" "$ADMINFRONT_BASE"
login_via_oidc "adminB@test.com" "localhost" "$ADMINFRONT_B_PORT" "$jar_admin_b" "$ADMINFRONT_B_BASE"

ctx_a="$(fetch_json "${BACKEND_BASE}/api/v1/admin/context" "$jar_admin_a" "localhost:3000")"
marketplace_a_id="$(printf "%s" "$ctx_a" | json_get "data.marketplaces.0.id")"
ctx_b="$(fetch_json "${BACKEND_BASE}/api/v1/admin/context" "$jar_admin_b" "localhost:${ADMINFRONT_B_PORT}")"
marketplace_b_id="$(printf "%s" "$ctx_b" | json_get "data.marketplaces.0.id")"

if [[ -z "$marketplace_a_id" || -z "$marketplace_b_id" ]]; then
  echo "Missing marketplace ids from admin context" >&2
  exit 1
fi

echo "-- Ensure org-b sharing scope is global (so products can be reused across tenants)"
settings_global_b="$tmpdir/settings_global_b.json"
cat >"$settings_global_b" <<JSON
{
  "settings": {
    "general": {
      "store_name": "Organization 2 Control Room",
      "branding": "Global catalog enabled for smoke test.",
      "logo": null
    },
    "product_settings": {
      "allow_product_sharing": true,
      "isolation_mode": false
    },
    "integrations": {
      "google_analytics_id": "",
      "meta_pixel_id": "",
      "future_api_notes": "Smoke test global sharing"
    }
  }
}
JSON
settings_b_response="$(write_json "PATCH" "${BACKEND_BASE}/api/v1/admin/settings?marketplace_id=${marketplace_b_id}" "$jar_admin_b" "$settings_global_b" "localhost:${ADMINFRONT_B_PORT}")"
sharing_scope_b="$(printf "%s" "$settings_b_response" | json_get "data.sharing_scope")"
assert_equals "$sharing_scope_b" "global" "sharing_scope_b"

echo "-- Resolve clothing product_type + a matching category"
product_types_a="$(fetch_json "${BACKEND_BASE}/api/v1/admin/product_types?marketplace_id=${marketplace_a_id}&per_page=200" "$jar_admin_a" "localhost:3000")"
clothing_type_id="$(python3 -c 'import json,sys
data=json.load(sys.stdin).get("data",[])
for pt in data:
  if pt.get("code")=="clothing":
    print(pt.get("id",""))
    raise SystemExit(0)
print("")' <<<"$product_types_a")"

if [[ -z "$clothing_type_id" ]]; then
  echo "Missing clothing product type seed data" >&2
  echo "$product_types_a" >&2
  exit 1
fi

categories_a="$(fetch_json "${BACKEND_BASE}/api/v1/admin/categories?marketplace_id=${marketplace_a_id}&product_type_id=${clothing_type_id}&per_page=1" "$jar_admin_a" "localhost:3000")"
category_id="$(printf "%s" "$categories_a" | json_get "data.0.id")"
category_product_type_id="$(printf "%s" "$categories_a" | json_get "data.0.product_type_id")"

if [[ -z "$category_id" || -z "$category_product_type_id" ]]; then
  echo "Missing clothing category seed data" >&2
  echo "$categories_a" >&2
  exit 1
fi

assert_equals "$category_product_type_id" "$clothing_type_id" "category_product_type_id"

suffix="$(date +%s)-$RANDOM"
product_name="Global Tee ${suffix}"
product_sku="GLOBAL-TEE-${suffix}"
variant_sku="GLOBAL-TEE-${suffix}-M-BLK"

create_a="$tmpdir/create_a.json"
cat >"$create_a" <<JSON
{
  "listing": {
    "force_create": true,
    "price_cents": 1299,
    "currency": "INR",
    "status": "active",
    "inventory_count": 20,
    "product": {
      "name": "${product_name}",
      "sku": "${product_sku}",
      "category_id": ${category_id},
      "product_type_id": ${clothing_type_id}
    },
    "variant": {
      "name": "M / Black",
      "sku": "${variant_sku}"
    },
    "product_metadata": {
      "brand": "Acme",
      "material": "Cotton",
      "fit": "Regular"
    },
    "variant_options": {
      "size": "M",
      "color": "Black"
    }
  }
}
JSON

echo "-- Create listing for tenant A (creates global product + variant)"
create_a_resp="$(write_json "POST" "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_a_id}" "$jar_admin_a" "$create_a" "localhost:3000")"
listing_a_id="$(printf "%s" "$create_a_resp" | json_get "data.id")"
product_id_a="$(printf "%s" "$create_a_resp" | json_get "data.product.id")"
variant_id_a="$(printf "%s" "$create_a_resp" | json_get "data.variant.id")"
inv_a="$(printf "%s" "$create_a_resp" | json_get "data.inventory_count")"

if [[ -z "$listing_a_id" || -z "$product_id_a" || -z "$variant_id_a" ]]; then
  echo "Create A response missing ids" >&2
  echo "$create_a_resp" >&2
  exit 1
fi
assert_equals "$inv_a" "20" "inventory_a"

echo "-- Tenant B: request suggestions for the same product name"
suggest_b="$tmpdir/suggest_b.json"
cat >"$suggest_b" <<JSON
{
  "listing": {
    "force_create": false,
    "price_cents": 1299,
    "currency": "INR",
    "status": "active",
    "product": {
      "name": "${product_name}",
      "sku": "TENANTB-SKU-${suffix}",
      "category_id": ${category_id},
      "product_type_id": ${clothing_type_id}
    },
    "variant": {
      "name": "M / Black",
      "sku": "TENANTB-VSKU-${suffix}"
    },
    "product_metadata": {
      "brand": "Acme",
      "material": "Cotton",
      "fit": "Regular"
    },
    "variant_options": {
      "size": "M",
      "color": "Black"
    }
  }
}
JSON

suggest_out="$tmpdir/suggest_out.json"
suggest_code="$(write_json_with_code "POST" "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_b_id}" "$jar_admin_b" "$suggest_b" "localhost:${ADMINFRONT_B_PORT}" "$suggest_out")"
assert_equals "$suggest_code" "409" "suggestions_http_code"

suggested_product_id="$(cat "$suggest_out" | json_get "meta.suggestions.0.product_id")"
assert_equals "$suggested_product_id" "$product_id_a" "suggested_product_id"

echo "-- Tenant B: reuse suggested product + create listing with isolated inventory"
create_b="$tmpdir/create_b.json"
cat >"$create_b" <<JSON
{
  "listing": {
    "reuse_product_id": ${product_id_a},
    "force_create": false,
    "price_cents": 1399,
    "currency": "INR",
    "status": "active",
    "inventory_count": 7,
    "variant": {
      "name": "M / Black",
      "sku": "${variant_sku}"
    },
    "variant_options": {
      "size": "M",
      "color": "Black"
    }
  }
}
JSON

create_b_resp="$(write_json "POST" "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_b_id}" "$jar_admin_b" "$create_b" "localhost:${ADMINFRONT_B_PORT}")"
listing_b_id="$(printf "%s" "$create_b_resp" | json_get "data.id")"
product_id_b="$(printf "%s" "$create_b_resp" | json_get "data.product.id")"
variant_id_b="$(printf "%s" "$create_b_resp" | json_get "data.variant.id")"
inv_b="$(printf "%s" "$create_b_resp" | json_get "data.inventory_count")"

if [[ -z "$listing_b_id" || -z "$product_id_b" || -z "$variant_id_b" ]]; then
  echo "Create B response missing ids" >&2
  echo "$create_b_resp" >&2
  exit 1
fi

assert_not_equals "$listing_b_id" "$listing_a_id" "listing_id"
assert_equals "$product_id_b" "$product_id_a" "product_id"
assert_equals "$variant_id_b" "$variant_id_a" "variant_id"
assert_equals "$inv_b" "7" "inventory_b"

echo "-- Verify inventory isolation by updating tenant A listing only"
update_a="$tmpdir/update_a.json"
cat >"$update_a" <<JSON
{ "listing": { "inventory_count": 30, "price_cents": 1299, "currency": "INR", "status": "active" } }
JSON
update_a_resp="$(write_json "PATCH" "${BACKEND_BASE}/api/v1/admin/listings/${listing_a_id}?marketplace_id=${marketplace_a_id}" "$jar_admin_a" "$update_a" "localhost:3000")"
inv_a_updated="$(printf "%s" "$update_a_resp" | json_get "data.inventory_count")"
assert_equals "$inv_a_updated" "30" "inventory_a_updated"

fetch_b="$tmpdir/fetch_b.json"
fetch_b_code="$(
  curl -sS -o "$fetch_b" -w "%{http_code}" \
    -b "$jar_admin_b" -c "$jar_admin_b" \
    -H "Accept: application/json" \
    -H "X-Forwarded-Host: localhost:${ADMINFRONT_B_PORT}" \
    -H "X-Forwarded-Port: ${ADMINFRONT_B_PORT}" \
    "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_b_id}&per_page=200"
)"
assert_equals "$fetch_b_code" "200" "fetch_b_code"
inv_b_after="$(cat "$fetch_b" | python3 -c 'import json,sys
data=json.load(sys.stdin).get("data",[])
for row in data:
  if str(row.get("id"))==sys.argv[1]:
    print(row.get("inventory_count",""))
    raise SystemExit(0)
print("")' "$listing_b_id")"
assert_equals "$inv_b_after" "7" "inventory_b_after"

echo
echo "OK: product system smoke test passed."
