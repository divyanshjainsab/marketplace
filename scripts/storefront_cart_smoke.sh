#!/usr/bin/env bash
set -euo pipefail

BACKEND_BASE="${BACKEND_BASE:-http://localhost:3001}"
TENANT_HOST="${TENANT_HOST:-localhost:3002}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

headers=(
  -H "Accept: application/json"
  -H "Content-Type: application/json"
  -H "Host: ${TENANT_HOST}"
)

cart_id="$(python3 -c 'import uuid; print(uuid.uuid4())')"

listing_json="$(curl -sS "${headers[@]}" "${BACKEND_BASE}/api/listings?status=active&per_page=50")"
variant_id="$(python3 -c 'import json,sys
payload=json.loads(sys.stdin.read())
items=payload.get("data", [])
for row in items:
  inv=int(row.get("inventory_count") or 0)
  if inv >= 3 and row.get("variant") and row["variant"].get("id"):
    print(row["variant"]["id"])
    raise SystemExit(0)
print("")' <<<"$listing_json")"

if [[ -z "$variant_id" ]]; then
  echo "No active listing with inventory_count >= 3 found for tenant ${TENANT_HOST}" >&2
  exit 1
fi

curl -sS -o /dev/null "${headers[@]}" \
  -X POST "${BACKEND_BASE}/api/cart/items?session_id=${cart_id}" \
  --data "{\"variant_id\":${variant_id},\"quantity\":2}"

cart_json="$(curl -sS "${headers[@]}" "${BACKEND_BASE}/api/cart?session_id=${cart_id}")"
item_count="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["item_count"])' <<<"$cart_json")"

curl -sS -o /dev/null "${headers[@]}" \
  -X PATCH "${BACKEND_BASE}/api/cart/items/${variant_id}?session_id=${cart_id}" \
  --data "{\"quantity\":3}"

cart_json="$(curl -sS "${headers[@]}" "${BACKEND_BASE}/api/cart?session_id=${cart_id}")"
quantity="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["items"][0]["quantity"])' <<<"$cart_json")"

curl -sS -o /dev/null "${headers[@]}" \
  -X DELETE "${BACKEND_BASE}/api/cart/items/${variant_id}?session_id=${cart_id}"

cart_json="$(curl -sS "${headers[@]}" "${BACKEND_BASE}/api/cart?session_id=${cart_id}")"
final_count="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["item_count"])' <<<"$cart_json")"

printf "CART_ID=%s\n" "$cart_id"
printf "VARIANT_ID=%s\n" "$variant_id"
printf "AFTER_ADD_ITEM_COUNT=%s\n" "$item_count"
printf "AFTER_UPDATE_QUANTITY=%s\n" "$quantity"
printf "AFTER_REMOVE_ITEM_COUNT=%s\n" "$final_count"
