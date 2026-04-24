#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BACKEND_BASE="${BACKEND_BASE:-http://localhost:3015}"
SSO_BASE="${SSO_BASE:-http://localhost:3001}"
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
  local tenant_hostport="${3:-}"
  curl -sS \
    -b "$jar" -c "$jar" \
    -H "Accept: application/json" \
    -H "X-Forwarded-Host: ${tenant_hostport}" \
    -H "X-Forwarded-Port: ${tenant_hostport##*:}" \
    "$url"
}

function assert_contains() {
  local hay="$1"
  local needle="$2"
  if ! grep -q "$needle" <<<"$hay"; then
    echo "Expected to find '${needle}'" >&2
    return 1
  fi
}

function assert_not_contains() {
  local hay="$1"
  local needle="$2"
  if grep -q "$needle" <<<"$hay"; then
    echo "Expected NOT to find '${needle}'" >&2
    return 1
  fi
}

echo "== Admin listings CRUD smoke test (Docker runtime) =="
echo "Backend: ${BACKEND_BASE}"
echo "SSO: ${SSO_BASE}"
echo "Adminfront: ${ADMINFRONT_BASE}"
echo

jar_admin="$tmpdir/adminA.cookies"
jar_admin_b="$tmpdir/adminB.cookies"

login_via_oidc "adminA@test.com" "localhost" "3000" "$jar_admin" "$ADMINFRONT_BASE"
login_via_oidc "adminB@test.com" "localhost" "$ADMINFRONT_B_PORT" "$jar_admin_b" "$ADMINFRONT_B_BASE"

ctx_a="$(fetch_json "${BACKEND_BASE}/api/v1/admin/context" "$jar_admin" "localhost:3000")"
marketplace_a_id="$(printf "%s" "$ctx_a" | json_get "data.marketplaces.0.id")"
ctx_b="$(fetch_json "${BACKEND_BASE}/api/v1/admin/context" "$jar_admin_b" "localhost:${ADMINFRONT_B_PORT}")"
marketplace_b_id="$(printf "%s" "$ctx_b" | json_get "data.marketplaces.0.id")"
category_id="$(fetch_json "${BACKEND_BASE}/api/v1/admin/categories?marketplace_id=${marketplace_a_id}&per_page=1" "$jar_admin" "localhost:3000" | json_get "data.0.id")"
product_type_id="$(fetch_json "${BACKEND_BASE}/api/v1/admin/product_types?marketplace_id=${marketplace_a_id}&per_page=1" "$jar_admin" "localhost:3000" | json_get "data.0.id")"

if [[ -z "$category_id" || -z "$product_type_id" ]]; then
  echo "Missing category or product type seed data" >&2
  exit 1
fi

suffix="$(date +%s)-$RANDOM"
product_name="Smoke Product ${suffix}"
product_sku="SMOKE-PRODUCT-${suffix}"
variant_name="Smoke Variant ${suffix}"
variant_sku="SMOKE-VARIANT-${suffix}"

create_payload="$tmpdir/create_payload.json"
cat >"$create_payload" <<JSON
{
  "listing": {
    "force_create": true,
    "price_cents": 199900,
    "currency": "INR",
    "status": "draft",
    "product": {
      "name": "${product_name}",
      "sku": "${product_sku}",
      "category_id": ${category_id},
      "product_type_id": ${product_type_id}
    },
    "variant": {
      "name": "${variant_name}",
      "sku": "${variant_sku}"
    }
  }
}
JSON

echo "-- Create listing in org-a"
create_response="$(
  curl -sS \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: localhost:3000" \
    -H "X-Forwarded-Port: 3000" \
    -X POST "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_a_id}" \
    --data @"$create_payload"
)"
listing_id="$(printf "%s" "$create_response" | json_get "data.id")"
currency="$(printf "%s" "$create_response" | json_get "data.currency")"
status="$(printf "%s" "$create_response" | json_get "data.status")"
if [[ -z "$listing_id" ]]; then
  echo "Create response missing listing id" >&2
  echo "$create_response" >&2
  exit 1
fi
if [[ "$currency" != "INR" || "$status" != "draft" ]]; then
  echo "Unexpected create payload: currency=${currency}, status=${status}" >&2
  exit 1
fi

echo "-- Verify listing visible only in org-a"
listings_a="$(fetch_json "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_a_id}&per_page=100" "$jar_admin" "localhost:3000")"
assert_contains "$listings_a" "$product_sku"
listings_b="$(fetch_json "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_b_id}&per_page=100" "$jar_admin_b" "localhost:${ADMINFRONT_B_PORT}")"
assert_not_contains "$listings_b" "$product_sku"

echo "-- Update listing price and status"
update_response="$(
  curl -sS \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: localhost:3000" \
    -H "X-Forwarded-Port: 3000" \
    -X PATCH "${BACKEND_BASE}/api/v1/admin/listings/${listing_id}?marketplace_id=${marketplace_a_id}" \
    --data '{"listing":{"price_cents":249900,"currency":"INR","status":"active"}}'
)"
updated_price="$(printf "%s" "$update_response" | json_get "data.price_cents")"
updated_status="$(printf "%s" "$update_response" | json_get "data.status")"
if [[ "$updated_price" != "249900" || "$updated_status" != "active" ]]; then
  echo "Update failed: price=${updated_price}, status=${updated_status}" >&2
  echo "$update_response" >&2
  exit 1
fi

echo "-- Reject invalid INR override"
invalid_code="$(
  curl -sS -o /dev/null -w "%{http_code}" \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: localhost:3000" \
    -H "X-Forwarded-Port: 3000" \
    -X PATCH "${BACKEND_BASE}/api/v1/admin/listings/${listing_id}?marketplace_id=${marketplace_a_id}" \
    --data '{"listing":{"price_cents":249900,"currency":"USD","status":"active"}}'
)"
if [[ "$invalid_code" != "422" ]]; then
  echo "Expected 422 for invalid currency override, got ${invalid_code}" >&2
  exit 1
fi

echo "-- Block cross-tenant mutation"
cross_tenant_code="$(
  curl -sS -o /dev/null -w "%{http_code}" \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: localhost:3000" \
    -H "X-Forwarded-Port: 3000" \
    -X POST "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_b_id}" \
    --data @"$create_payload"
)"
if [[ "$cross_tenant_code" != "404" ]]; then
  echo "Expected 404 for cross-tenant listing create, got ${cross_tenant_code}" >&2
  exit 1
fi

echo "-- Delete listing"
delete_code="$(
  curl -sS -o /dev/null -w "%{http_code}" \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: localhost:3000" \
    -H "X-Forwarded-Port: 3000" \
    -X DELETE "${BACKEND_BASE}/api/v1/admin/listings/${listing_id}?marketplace_id=${marketplace_a_id}"
)"
if [[ "$delete_code" != "204" ]]; then
  echo "Expected 204 for delete, got ${delete_code}" >&2
  exit 1
fi
listings_after_delete="$(fetch_json "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_a_id}&per_page=100" "$jar_admin" "localhost:3000")"
assert_not_contains "$listings_after_delete" "$product_sku"

echo
echo "OK: admin listings CRUD smoke test passed."
