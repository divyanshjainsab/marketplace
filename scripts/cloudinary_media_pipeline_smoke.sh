#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BACKEND_BASE="${BACKEND_BASE:-http://localhost:3015}"
SSO_BASE="${SSO_BASE:-http://localhost:3001}"
ADMINFRONT_BASE="${ADMINFRONT_BASE:-http://localhost:3000}"
CLIENTFRONT_BASE="${CLIENTFRONT_BASE:-http://localhost:3002}"
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

function upload_media_asset() {
  local jar="$1"
  local tenant_hostport="$2"
  local marketplace_id="$3"
  local target="$4"
  local file="$5"

  curl -sS \
    -b "$jar" -c "$jar" \
    -H "Accept: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: ${tenant_hostport}" \
    -H "X-Forwarded-Port: ${tenant_hostport##*:}" \
    -X POST "${BACKEND_BASE}/api/v1/admin/media_assets?marketplace_id=${marketplace_id}&target=${target}" \
    -F "file=@${file};type=image/png"
}

echo "== Cloudinary media pipeline smoke test =="
echo "Backend: ${BACKEND_BASE}"
echo "SSO: ${SSO_BASE}"
echo "Adminfront: ${ADMINFRONT_BASE}"
echo "Clientfront: ${CLIENTFRONT_BASE}"
echo

jar_admin="$tmpdir/admin.cookies"
login_via_oidc "adminA@test.com" "localhost" "3000" "$jar_admin" "$ADMINFRONT_BASE"

context_payload="$(
  curl -sS \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "X-Forwarded-Host: localhost:3000" \
    -H "X-Forwarded-Port: 3000" \
    "${BACKEND_BASE}/api/v1/admin/context"
)"

marketplace_id="$(printf "%s" "$context_payload" | json_get "data.marketplaces.0.id")"
marketplace_custom_domain="$(printf "%s" "$context_payload" | json_get "data.marketplaces.0.custom_domain")"
category_id="$(
  curl -sS \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "X-Forwarded-Host: ${marketplace_custom_domain}" \
    -H "X-Forwarded-Port: ${marketplace_custom_domain##*:}" \
    "${BACKEND_BASE}/api/v1/categories?per_page=1" | json_get "data.0.id"
)"
product_type_id="$(
  curl -sS \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "X-Forwarded-Host: ${marketplace_custom_domain}" \
    -H "X-Forwarded-Port: ${marketplace_custom_domain##*:}" \
    "${BACKEND_BASE}/api/v1/product_types?per_page=1" | json_get "data.0.id"
)"

if [[ -z "$marketplace_id" || -z "$marketplace_custom_domain" || -z "$category_id" || -z "$product_type_id" ]]; then
  echo "Missing required seed data" >&2
  exit 1
fi

tiny_png="$tmpdir/tiny.png"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7ZsXQAAAAASUVORK5CYII=' | base64 -d > "$tiny_png"

echo "-- Upload product, variant, listing, and site-editor media assets"
product_asset="$(upload_media_asset "$jar_admin" "localhost:3000" "$marketplace_id" "product" "$tiny_png")"
variant_asset="$(upload_media_asset "$jar_admin" "localhost:3000" "$marketplace_id" "variant" "$tiny_png")"
listing_asset="$(upload_media_asset "$jar_admin" "localhost:3000" "$marketplace_id" "listing" "$tiny_png")"
hero_asset_v1="$(upload_media_asset "$jar_admin" "localhost:3000" "$marketplace_id" "site_editor" "$tiny_png")"
promo_asset="$(upload_media_asset "$jar_admin" "localhost:3000" "$marketplace_id" "site_editor" "$tiny_png")"
hero_asset_v2="$(upload_media_asset "$jar_admin" "localhost:3000" "$marketplace_id" "site_editor" "$tiny_png")"

product_asset_url="$(printf "%s" "$product_asset" | json_get "data.optimized_url")"
listing_asset_public_id="$(printf "%s" "$listing_asset" | json_get "data.public_id")"
if [[ "$product_asset_url" != https://res*.cloudinary.com/* ]]; then
  echo "Expected product upload to return a Cloudinary optimized_url" >&2
  echo "$product_asset" >&2
  exit 1
fi
if [[ "$listing_asset_public_id" != marketplace/* ]]; then
  echo "Expected listing upload to return a namespaced Cloudinary public_id" >&2
  echo "$listing_asset" >&2
  exit 1
fi

export PRODUCT_ASSET_JSON="$product_asset"
export VARIANT_ASSET_JSON="$variant_asset"
export LISTING_ASSET_JSON="$listing_asset"

suffix="$(date +%s)-$RANDOM"
product_name="Cloudinary Smoke Product ${suffix}"
product_sku="CLOUDINARY-PRODUCT-${suffix}"
variant_name="Cloudinary Smoke Variant ${suffix}"
variant_sku="CLOUDINARY-VARIANT-${suffix}"

create_payload="$tmpdir/create_listing.json"
export CATEGORY_ID="$category_id"
export PRODUCT_TYPE_ID="$product_type_id"
export PRODUCT_NAME="$product_name"
export PRODUCT_SKU="$product_sku"
export VARIANT_NAME="$variant_name"
export VARIANT_SKU="$variant_sku"
python3 - <<'PY' > "$create_payload"
import json
import os

payload = {
    "listing": {
        "force_create": True,
        "price_cents": 219900,
        "currency": "INR",
        "status": "active",
        "image_data": json.loads(os.environ["LISTING_ASSET_JSON"])["data"],
        "product": {
            "name": os.environ["PRODUCT_NAME"],
            "sku": os.environ["PRODUCT_SKU"],
            "category_id": int(os.environ["CATEGORY_ID"]),
            "product_type_id": int(os.environ["PRODUCT_TYPE_ID"]),
            "image_data": json.loads(os.environ["PRODUCT_ASSET_JSON"])["data"],
        },
        "variant": {
            "name": os.environ["VARIANT_NAME"],
            "sku": os.environ["VARIANT_SKU"],
            "image_data": json.loads(os.environ["VARIANT_ASSET_JSON"])["data"],
        },
    }
}

json.dump(payload, open(os.devnull, "w"))
print(json.dumps(payload))
PY

echo "-- Create listing with Cloudinary-backed product, variant, and listing media"
create_response="$(
  curl -sS \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: localhost:3000" \
    -H "X-Forwarded-Port: 3000" \
    -X POST "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${marketplace_id}" \
    --data @"$create_payload"
)"

listing_id="$(printf "%s" "$create_response" | json_get "data.id")"
product_id="$(printf "%s" "$create_response" | json_get "data.product.id")"
image_source="$(printf "%s" "$create_response" | json_get "data.image_source")"
image_url="$(printf "%s" "$create_response" | json_get "data.image_url")"
product_public_id="$(printf "%s" "$create_response" | json_get "data.product.image.public_id")"
variant_public_id="$(printf "%s" "$create_response" | json_get "data.variant.image.public_id")"

if [[ -z "$listing_id" || -z "$product_id" ]]; then
  echo "Create response missing listing or product id" >&2
  echo "$create_response" >&2
  exit 1
fi
if [[ "$image_source" != "listing" ]]; then
  echo "Expected listing image source, got ${image_source}" >&2
  exit 1
fi
assert_contains "$image_url" "https://res"
if [[ -z "$product_public_id" || -z "$variant_public_id" ]]; then
  echo "Expected product and variant Cloudinary metadata in create response" >&2
  echo "$create_response" >&2
  exit 1
fi

export HERO_ASSET_V1_JSON="$hero_asset_v1"
export PROMO_ASSET_JSON="$promo_asset"
export FEATURED_PRODUCT_ID="$product_id"
export FEATURED_LISTING_ID="$listing_id"

site_editor_payload_v1="$tmpdir/site_editor_v1.json"
python3 - <<'PY' > "$site_editor_payload_v1"
import json
import os

payload = {
    "homepage_config": {
        "layout_order": [
            "hero_banner",
            "featured_products",
            "featured_listings",
            "categories",
            "promotional_blocks",
        ],
        "hero_banner": {
            "title": "Cloudinary Hero",
            "subtitle": "Versioned media should render directly from Cloudinary.",
            "cta_text": "Browse products",
            "cta_href": "/products",
            "image": json.loads(os.environ["HERO_ASSET_V1_JSON"])["data"],
        },
        "featured_products": [int(os.environ["FEATURED_PRODUCT_ID"])],
        "featured_listings": [int(os.environ["FEATURED_LISTING_ID"])],
        "categories": [],
        "promotional_blocks": [
            {
                "title": "CDN delivery",
                "body": "Images must come from Cloudinary, not the Rails backend.",
                "href": "/products",
                "image": json.loads(os.environ["PROMO_ASSET_JSON"])["data"],
            }
        ],
    }
}

print(json.dumps(payload))
PY

echo "-- Save site-editor config with Cloudinary hero and promo media"
site_editor_response_v1="$(
  curl -sS \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: localhost:3000" \
    -H "X-Forwarded-Port: 3000" \
    -X PATCH "${BACKEND_BASE}/api/v1/admin/site_editor?marketplace_id=${marketplace_id}" \
    --data @"$site_editor_payload_v1"
)"
hero_public_id_v1="$(printf "%s" "$site_editor_response_v1" | json_get "data.homepage_config.hero_banner.image.public_id")"
hero_url_v1="$(printf "%s" "$site_editor_response_v1" | json_get "data.homepage_config.hero_banner.image.optimized_url")"

if [[ -z "$hero_public_id_v1" || -z "$hero_url_v1" ]]; then
  echo "Site editor response missing hero media metadata" >&2
  echo "$site_editor_response_v1" >&2
  exit 1
fi

echo "-- Verify homepage API payload and cache headers"
homepage_headers="$(
  curl -sS -D - -o /dev/null \
    -H "Accept: application/json" \
    -H "X-Forwarded-Host: ${marketplace_custom_domain}" \
    -H "X-Forwarded-Port: ${marketplace_custom_domain##*:}" \
    "${BACKEND_BASE}/api/v1/homepage"
)"
homepage_headers_lower="$(printf "%s" "$homepage_headers" | tr '[:upper:]' '[:lower:]')"
assert_contains "$homepage_headers_lower" "cache-control: max-age=60, public, stale-while-revalidate=30"

homepage_payload_v1="$(
  curl -sS \
    -H "Accept: application/json" \
    -H "X-Forwarded-Host: ${marketplace_custom_domain}" \
    -H "X-Forwarded-Port: ${marketplace_custom_domain##*:}" \
    "${BACKEND_BASE}/api/v1/homepage"
)"
homepage_hero_public_id_v1="$(printf "%s" "$homepage_payload_v1" | json_get "data.homepage_config.hero_banner.image.public_id")"
homepage_listing_image_source_v1="$(printf "%s" "$homepage_payload_v1" | json_get "data.resolved.featured_listings.0.image_source")"
homepage_listing_image_url_v1="$(printf "%s" "$homepage_payload_v1" | json_get "data.resolved.featured_listings.0.image.optimized_url")"
if [[ "$homepage_hero_public_id_v1" != "$hero_public_id_v1" ]]; then
  echo "Homepage payload did not include the saved hero public_id" >&2
  echo "$homepage_payload_v1" >&2
  exit 1
fi
if [[ "$homepage_listing_image_source_v1" != "listing" ]]; then
  echo "Homepage payload did not preserve listing image precedence" >&2
  echo "$homepage_payload_v1" >&2
  exit 1
fi
if [[ "$homepage_listing_image_url_v1" != https://res*.cloudinary.com/* ]]; then
  echo "Homepage payload did not expose a Cloudinary listing image URL" >&2
  echo "$homepage_payload_v1" >&2
  exit 1
fi

echo "-- Verify clientfront homepage renders direct Cloudinary URLs"
client_home_html="$(curl -sS "${CLIENTFRONT_BASE}/")"
assert_contains "$client_home_html" "cloudinary.com"
assert_not_contains "$client_home_html" "/_next/image"
assert_not_contains "$client_home_html" "${BACKEND_BASE}"

echo "-- Verify Cloudinary delivery response exposes cache headers"
cloudinary_headers="$(curl -sS -I "${hero_url_v1}")"
cloudinary_headers_lower="$(printf "%s" "$cloudinary_headers" | tr '[:upper:]' '[:lower:]')"
assert_contains "$cloudinary_headers_lower" "cache-control"

export HERO_ASSET_V2_JSON="$hero_asset_v2"
site_editor_payload_v2="$tmpdir/site_editor_v2.json"
python3 - <<'PY' > "$site_editor_payload_v2"
import json
import os

payload = {
    "homepage_config": {
        "layout_order": [
            "hero_banner",
            "featured_products",
            "featured_listings",
            "categories",
            "promotional_blocks",
        ],
        "hero_banner": {
            "title": "Cloudinary Hero",
            "subtitle": "A new asset version should invalidate the old CDN URL cleanly.",
            "cta_text": "Browse products",
            "cta_href": "/products",
            "image": json.loads(os.environ["HERO_ASSET_V2_JSON"])["data"],
        },
        "featured_products": [int(os.environ["FEATURED_PRODUCT_ID"])],
        "featured_listings": [int(os.environ["FEATURED_LISTING_ID"])],
        "categories": [],
        "promotional_blocks": [
            {
                "title": "CDN delivery",
                "body": "Images must come from Cloudinary, not the Rails backend.",
                "href": "/products",
                "image": json.loads(os.environ["PROMO_ASSET_JSON"])["data"],
            }
        ],
    }
}

print(json.dumps(payload))
PY

echo "-- Replace hero image and verify the versioned asset changes"
site_editor_response_v2="$(
  curl -sS \
    -b "$jar_admin" -c "$jar_admin" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Frontend-Proxy: 1" \
    -H "X-Forwarded-Host: localhost:3000" \
    -H "X-Forwarded-Port: 3000" \
    -X PATCH "${BACKEND_BASE}/api/v1/admin/site_editor?marketplace_id=${marketplace_id}" \
    --data @"$site_editor_payload_v2"
)"
hero_public_id_v2="$(printf "%s" "$site_editor_response_v2" | json_get "data.homepage_config.hero_banner.image.public_id")"
hero_url_v2="$(printf "%s" "$site_editor_response_v2" | json_get "data.homepage_config.hero_banner.image.optimized_url")"

if [[ -z "$hero_public_id_v2" || "$hero_public_id_v1" == "$hero_public_id_v2" ]]; then
  echo "Expected a new hero public_id after replacing the image" >&2
  exit 1
fi
if [[ -z "$hero_url_v2" || "$hero_url_v1" == "$hero_url_v2" ]]; then
  echo "Expected a new hero optimized_url after replacing the image" >&2
  exit 1
fi

homepage_payload_v2="$(
  curl -sS \
    -H "Accept: application/json" \
    -H "X-Forwarded-Host: ${marketplace_custom_domain}" \
    -H "X-Forwarded-Port: ${marketplace_custom_domain##*:}" \
    "${BACKEND_BASE}/api/v1/homepage"
)"
homepage_hero_public_id_v2="$(printf "%s" "$homepage_payload_v2" | json_get "data.homepage_config.hero_banner.image.public_id")"
if [[ "$homepage_hero_public_id_v2" != "$hero_public_id_v2" ]]; then
  echo "Homepage payload did not reflect the updated hero public_id" >&2
  echo "$homepage_payload_v2" >&2
  exit 1
fi
if [[ "$homepage_hero_public_id_v2" == "$hero_public_id_v1" ]]; then
  echo "Homepage payload still references the stale hero public_id" >&2
  echo "$homepage_payload_v2" >&2
  exit 1
fi

echo
echo "Cloudinary media pipeline smoke test passed."
