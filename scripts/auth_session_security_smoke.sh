#!/usr/bin/env bash
set -euo pipefail

BACKEND_BASE="${BACKEND_BASE:-http://localhost:3001}"
SSO_BASE="${SSO_BASE:-http://localhost:3003}"
PASSWORD="${SEED_PASSWORD:-Password123!}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

jar="$tmpdir/admina.cookies"
start_headers="$tmpdir/start.headers"
callback_headers="$tmpdir/callback.headers"

curl -sS -D "$start_headers" -o /dev/null \
  -c "$jar" -b "$jar" \
  "${BACKEND_BASE}/auth/oidc/start/admin?return_to=%2Fdashboard&origin_host=localhost&origin_port=3000&origin_scheme=http"

authorize_url="$(awk -F': ' 'tolower($1)=="location"{print $2}' "$start_headers" | tr -d '\r' | tail -n1)"
if [[ -z "$authorize_url" ]]; then
  echo "Missing authorize redirect" >&2
  exit 1
fi

curl -sS -D /dev/null -o /dev/null -c "$jar" -b "$jar" "$authorize_url"

login_json="$(
  curl -sS \
    -c "$jar" -b "$jar" \
    -H "Accept: application/json" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -X POST "${SSO_BASE}/login.json" \
    --data-urlencode "user[email]=adminA@test.com" \
    --data-urlencode "user[password]=${PASSWORD}"
)"

redirect_url="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["redirect_url"])' <<<"$login_json")"
curl -sS -D "$callback_headers" -o /dev/null -c "$jar" -b "$jar" "$redirect_url"

final_location="$(awk -F': ' 'tolower($1)=="location"{print $2}' "$callback_headers" | tr -d '\r' | tail -n1)"
contains_access_token="$(python3 -c 'import sys,urllib.parse; print("true" if "access_token" in urllib.parse.urlparse(sys.argv[1]).query else "false")' "$final_location")"

old_refresh="$(awk -F '\t' '$6=="mp_refresh"{print $7}' "$jar" | tail -n1)"
first_refresh_status="$(curl -sS -o /dev/null -w "%{http_code}" -X POST -H "X-Frontend-Proxy: 1" -H "Cookie: mp_refresh=${old_refresh}" "${BACKEND_BASE}/auth/session/refresh")"
second_refresh_status="$(curl -sS -o /dev/null -w "%{http_code}" -X POST -H "X-Frontend-Proxy: 1" -H "Cookie: mp_refresh=${old_refresh}" "${BACKEND_BASE}/auth/session/refresh")"
invalid_token_status="$(curl -sS -o /dev/null -w "%{http_code}" -H "Cookie: mp_access=bogus" -H "X-Forwarded-Host: localhost:3000" -H "X-Forwarded-Port: 3000" "${BACKEND_BASE}/api/v1/admin/context")"
csrf_without_proxy_status="$(curl -sS -o /dev/null -w "%{http_code}" -X PATCH -b "$jar" -c "$jar" -H "Content-Type: application/json" -H "X-Forwarded-Host: localhost:3000" -H "X-Forwarded-Port: 3000" "${BACKEND_BASE}/api/v1/admin/site_editor?marketplace_id=1" --data '{"homepage_config":{}}')"

printf "FINAL_LOCATION=%s\n" "$final_location"
printf "REDIRECT_CONTAINS_ACCESS_TOKEN=%s\n" "$contains_access_token"
printf "FIRST_REFRESH_STATUS=%s\n" "$first_refresh_status"
printf "SECOND_REFRESH_STATUS=%s\n" "$second_refresh_status"
printf "INVALID_TOKEN_STATUS=%s\n" "$invalid_token_status"
printf "CSRF_WITHOUT_PROXY_STATUS=%s\n" "$csrf_without_proxy_status"
