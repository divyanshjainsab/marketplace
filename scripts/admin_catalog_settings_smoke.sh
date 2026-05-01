#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BACKEND_BASE="${BACKEND_BASE:-http://localhost:3001}"
SSO_BASE="${SSO_BASE:-http://localhost:3003}"
ADMINFRONT_BASE="${ADMINFRONT_BASE:-http://localhost:3000}"
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
  local tenant_hostport="${3:-localhost:3000}"

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
  local tenant_hostport="${5:-localhost:3000}"

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

function assert_contains() {
  local haystack="$1"
  local needle="$2"
  if ! grep -q "$needle" <<<"$haystack"; then
    echo "Expected to find '${needle}'" >&2
    return 1
  fi
}

function assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if grep -q "$needle" <<<"$haystack"; then
    echo "Expected NOT to find '${needle}'" >&2
    return 1
  fi
}

echo "== Admin catalog + settings smoke test =="
echo "Backend: ${BACKEND_BASE}"
echo "SSO: ${SSO_BASE}"
echo "Adminfront: ${ADMINFRONT_BASE}"
echo

jar_admin="$tmpdir/admin.cookies"
login_via_oidc "adminA@test.com" "localhost" "3000" "$jar_admin" "$ADMINFRONT_BASE"

context_payload="$(fetch_json "${BACKEND_BASE}/api/v1/admin/context" "$jar_admin" "localhost:3000")"
marketplace_id="$(printf "%s" "$context_payload" | json_get "data.marketplaces.0.id")"

if [[ -z "$marketplace_id" ]]; then
  echo "Missing marketplace_id from admin context" >&2
  exit 1
fi

suffix="$(date +%s)-$RANDOM"
category_name="Smoke Category ${suffix}"
product_type_name="Smoke Type ${suffix}"
product_name="Smoke Settings Product ${suffix}"
product_sku="SMOKE-SETTINGS-PRODUCT-${suffix}"
variant_sku="SMOKE-SETTINGS-VARIANT-${suffix}"

category_payload="$tmpdir/category.json"
product_type_payload="$tmpdir/product_type.json"
cat >"$product_type_payload" <<JSON
{
  "product_type": {
    "name": "${product_type_name}"
  }
}
JSON

echo "-- Create category and product type"
product_type_response="$(write_json "POST" "${BACKEND_BASE}/api/v1/admin/product_types?marketplace_id=${marketplace_id}" "$jar_admin" "$product_type_payload" "localhost:3000")"

product_type_id="$(printf "%s" "$product_type_response" | json_get "data.id")"

cat >"$category_payload" <<JSON
{
  "category": {
    "name": "${category_name}",
    "product_type_id": ${product_type_id}
  }
}
JSON

category_response="$(write_json "POST" "${BACKEND_BASE}/api/v1/admin/categories?marketplace_id=${marketplace_id}" "$jar_admin" "$category_payload" "localhost:3000")"
category_id="$(printf "%s" "$category_response" | json_get "data.id")"

if [[ -z "$category_id" || -z "$product_type_id" ]]; then
  echo "Failed to create category or product type" >&2
  echo "$category_response" >&2
  echo "$product_type_response" >&2
  exit 1
fi

categories_payload="$(fetch_json "${BACKEND_BASE}/api/v1/admin/categories?marketplace_id=${marketplace_id}&per_page=200" "$jar_admin" "localhost:3000")"
product_types_payload="$(fetch_json "${BACKEND_BASE}/api/v1/admin/product_types?marketplace_id=${marketplace_id}&per_page=200" "$jar_admin" "localhost:3000")"
assert_contains "$categories_payload" "$category_name"
assert_contains "$product_types_payload" "$product_type_name"

settings_global_payload="$tmpdir/settings_global.json"
cat >"$settings_global_payload" <<JSON
{
  "settings": {
    "general": {
      "store_name": "Organization 1 Control Room",
      "branding": "Global catalog enabled for collaborative merchandising.",
      "logo": null
    },
    "product_settings": {
      "allow_product_sharing": true,
      "isolation_mode": false
    },
    "integrations": {
      "google_analytics_id": "G-ORG1ADMIN",
      "meta_pixel_id": "PIXEL-ORG1",
      "future_api_notes": "Smoke test global sharing"
    }
  }
}
JSON

settings_org_only_payload="$tmpdir/settings_org_only.json"
cat >"$settings_org_only_payload" <<JSON
{
  "settings": {
    "general": {
      "store_name": "Organization 1 Control Room",
      "branding": "Organization-only sharing.",
      "logo": null
    },
    "product_settings": {
      "allow_product_sharing": true,
      "isolation_mode": true
    },
    "integrations": {
      "google_analytics_id": "G-ORG1ADMIN",
      "meta_pixel_id": "PIXEL-ORG1",
      "future_api_notes": "Smoke test organization-only sharing"
    }
  }
}
JSON

settings_disabled_payload="$tmpdir/settings_disabled.json"
cat >"$settings_disabled_payload" <<JSON
{
  "settings": {
    "general": {
      "store_name": "Organization 1 Control Room",
      "branding": "Sharing disabled for smoke test.",
      "logo": null
    },
    "product_settings": {
      "allow_product_sharing": false,
      "isolation_mode": true
    },
    "integrations": {
      "google_analytics_id": "G-ORG1ADMIN",
      "meta_pixel_id": "PIXEL-ORG1",
      "future_api_notes": "Smoke test disabled sharing"
    }
  }
}
JSON

echo "-- Save settings with global sharing enabled"
settings_response="$(write_json "PATCH" "${BACKEND_BASE}/api/v1/admin/settings?marketplace_id=${marketplace_id}" "$jar_admin" "$settings_global_payload" "localhost:3000")"
if [[ "$(printf "%s" "$settings_response" | json_get "data.sharing_scope")" != "global" ]]; then
  echo "Expected sharing_scope=global" >&2
  echo "$settings_response" >&2
  exit 1
fi

echo "-- Create listing using the new category and product type"
listing_payload="$tmpdir/listing.json"
cat >"$listing_payload" <<JSON
{
  "listing": {
    "force_create": true,
    "price_cents": 149900,
    "currency": "INR",
    "status": "draft",
    "inventory_count": 12,
    "product": {
      "name": "${product_name}",
      "sku": "${product_sku}",
      "category_id": ${category_id},
      "product_type_id": ${product_type_id}
    },
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

listing_response="$(write_json "POST" "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_id}" "$jar_admin" "$listing_payload" "localhost:3000")"
listing_id="$(printf "%s" "$listing_response" | json_get "data.id")"
listing_category_name="$(printf "%s" "$listing_response" | json_get "data.product.category.name")"
listing_product_type_name="$(printf "%s" "$listing_response" | json_get "data.product.product_type.name")"

if [[ -z "$listing_id" || "$listing_category_name" != "$category_name" || "$listing_product_type_name" != "$product_type_name" ]]; then
  echo "Listing create failed to use the new category or product type" >&2
  echo "$listing_response" >&2
  exit 1
fi

echo "-- Verify global product suggestions can see another organization's product"
global_suggestions="$(fetch_json "${BACKEND_BASE}/api/v1/products/suggestions?q=ORGB-PRODUCT" "$jar_admin" "localhost:3000")"
assert_contains "$global_suggestions" "ORGB-PRODUCT"

echo "-- Switch to organization-only isolation"
org_only_response="$(write_json "PATCH" "${BACKEND_BASE}/api/v1/admin/settings?marketplace_id=${marketplace_id}" "$jar_admin" "$settings_org_only_payload" "localhost:3000")"
if [[ "$(printf "%s" "$org_only_response" | json_get "data.sharing_scope")" != "organization" ]]; then
  echo "Expected sharing_scope=organization" >&2
  echo "$org_only_response" >&2
  exit 1
fi

isolated_cross_org="$(fetch_json "${BACKEND_BASE}/api/v1/products/suggestions?q=ORGB-PRODUCT" "$jar_admin" "localhost:3000")"
isolated_same_org="$(fetch_json "${BACKEND_BASE}/api/v1/products/suggestions?q=ORGA-PRODUCT" "$jar_admin" "localhost:3000")"
assert_not_contains "$isolated_cross_org" "ORGB-PRODUCT"
assert_contains "$isolated_same_org" "ORGA-PRODUCT"

echo "-- Disable sharing completely"
disabled_response="$(write_json "PATCH" "${BACKEND_BASE}/api/v1/admin/settings?marketplace_id=${marketplace_id}" "$jar_admin" "$settings_disabled_payload" "localhost:3000")"
if [[ "$(printf "%s" "$disabled_response" | json_get "data.sharing_scope")" != "disabled" ]]; then
  echo "Expected sharing_scope=disabled" >&2
  echo "$disabled_response" >&2
  exit 1
fi

disabled_suggestions="$(fetch_json "${BACKEND_BASE}/api/v1/products/suggestions?q=ORGA-PRODUCT" "$jar_admin" "localhost:3000")"
assert_not_contains "$disabled_suggestions" "ORGA-PRODUCT"

echo "-- Restore global sharing defaults"
write_json "PATCH" "${BACKEND_BASE}/api/v1/admin/settings?marketplace_id=${marketplace_id}" "$jar_admin" "$settings_global_payload" "localhost:3000" >/dev/null

echo "-- Delete smoke listing"
delete_code="$(
  curl -sS -o /dev/null -w "%{http_code}" \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: localhost:3000" \
    -H "X-Forwarded-Port: 3000" \
    -X DELETE "${BACKEND_BASE}/api/v1/admin/listings/${listing_id}?marketplace_id=${marketplace_id}"
)"
if [[ "$delete_code" != "204" ]]; then
  echo "Expected 204 when deleting smoke listing, got ${delete_code}" >&2
  exit 1
fi

echo
echo "OK: admin catalog + settings smoke test passed."
