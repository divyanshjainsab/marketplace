#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BACKEND_BASE="${BACKEND_BASE:-http://localhost:3015}"
SSO_BASE="${SSO_BASE:-http://localhost:3001}"
ADMINFRONT_BASE="${ADMINFRONT_BASE:-http://localhost:3000}"
ADMINFRONT_B_BASE="${ADMINFRONT_B_BASE:-http://localhost:3003}"
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
  frontend_base="${5:-$ADMINFRONT_BASE}"

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

  # Hit /authorize to stash the OIDC request in the SSO session.
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

  if [[ -z "$login_json" ]]; then
    echo "Empty login response for ${email}" >&2
    return 1
  fi

  local redirect_url
  redirect_url="$(printf "%s" "$login_json" | json_get "redirect_url" 2>/dev/null || true)"
  if [[ -z "$redirect_url" || "$redirect_url" == "None" ]]; then
    echo "Login failed for ${email}. Raw response:" >&2
    echo "$login_json" >&2
    return 2
  fi

  # Complete callback on backend to set mp_access/mp_refresh cookies and redirect
  # back to the adminfront origin.
  curl -sS -D /dev/null -o /dev/null \
    -c "$jar" -b "$jar" \
    "$redirect_url"

  if ! grep -q "mp_access" "$jar"; then
    echo "Backend callback did not establish an admin session for ${email}" >&2
    return 3
  fi
}

function assert_http_code() {
  local expected="$1"
  local url="$2"
  local jar="$3"
  local tenant_hostport="${4:-}"
  local code
  if [[ -n "$tenant_hostport" ]]; then
    code="$(curl -sS -o /dev/null -w "%{http_code}" -b "$jar" -c "$jar" -H "X-Forwarded-Host: ${tenant_hostport}" -H "X-Forwarded-Port: ${tenant_hostport##*:}" "$url")"
  else
    code="$(curl -sS -o /dev/null -w "%{http_code}" -b "$jar" -c "$jar" "$url")"
  fi
  if [[ "$code" != "$expected" ]]; then
    echo "Expected ${expected} for ${url} but got ${code}" >&2
    return 1
  fi
}

function assert_http_code_in() {
  local allowed_csv="$1"
  local url="$2"
  local jar="$3"
  local tenant_hostport="${4:-}"
  local code
  if [[ -n "$tenant_hostport" ]]; then
    code="$(curl -sS -o /dev/null -w "%{http_code}" -b "$jar" -c "$jar" -H "X-Forwarded-Host: ${tenant_hostport}" -H "X-Forwarded-Port: ${tenant_hostport##*:}" "$url")"
  else
    code="$(curl -sS -o /dev/null -w "%{http_code}" -b "$jar" -c "$jar" "$url")"
  fi

  IFS=',' read -r -a allowed_codes <<<"$allowed_csv"
  for allowed in "${allowed_codes[@]}"; do
    if [[ "$code" == "$allowed" ]]; then
      return 0
    fi
  done

  echo "Expected one of ${allowed_csv} for ${url} but got ${code}" >&2
  return 1
}

function fetch_json() {
  local url="$1"
  local jar="$2"
  local tenant_hostport="${3:-}"
  if [[ -n "$tenant_hostport" ]]; then
    curl -sS -b "$jar" -c "$jar" -H "Accept: application/json" -H "X-Forwarded-Host: ${tenant_hostport}" -H "X-Forwarded-Port: ${tenant_hostport##*:}" "$url"
  else
    curl -sS -b "$jar" -c "$jar" -H "Accept: application/json" "$url"
  fi
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

echo "== RBAC smoke test (Docker runtime) =="
echo "Backend: ${BACKEND_BASE}"
echo "SSO: ${SSO_BASE}"
echo "Adminfront: ${ADMINFRONT_BASE}"
echo "Adminfront (org-b): ${ADMINFRONT_B_BASE}"
echo

jar_super="$tmpdir/super.cookies"
jar_a="$tmpdir/adminA.cookies"
jar_b="$tmpdir/adminB.cookies"
jar_user="$tmpdir/user.cookies"
jar_a_denied="$tmpdir/adminA_denied.cookies"
jar_b_denied="$tmpdir/adminB_denied.cookies"
jar_user_denied="$tmpdir/user_denied.cookies"

echo "-- Super admin: login (org-a)"
login_via_oidc "superadmin@test.com" "localhost" "3000" "$jar_super" "$ADMINFRONT_BASE"
assert_http_code "200" "${BACKEND_BASE}/api/v1/admin/context" "$jar_super" "localhost:3000"
ctx="$(fetch_json "${BACKEND_BASE}/api/v1/admin/context" "$jar_super" "localhost:3000")"
assert_contains "$ctx" "\"slug\":\"org1\""
mkt_a_id="$(printf "%s" "$ctx" | json_get "data.marketplaces.0.id")"

echo "-- Super admin: switch tenant via port (org-b)"
ctx="$(fetch_json "${BACKEND_BASE}/api/v1/admin/context" "$jar_super" "localhost:3003")"
assert_contains "$ctx" "\"slug\":\"org2\""
mkt_b_id="$(printf "%s" "$ctx" | json_get "data.marketplaces.0.id")"

echo "-- Org admin A: org-a allowed"
login_via_oidc "adminA@test.com" "localhost" "3000" "$jar_a" "$ADMINFRONT_BASE"
ctx="$(fetch_json "${BACKEND_BASE}/api/v1/admin/context" "$jar_a" "localhost:3000")"
assert_contains "$ctx" "\"slug\":\"org1\""
listings="$(fetch_json "${BACKEND_BASE}/api/v1/admin/listings" "$jar_a" "localhost:3000")"
assert_contains "$listings" "ORGA-PRODUCT"
assert_not_contains "$listings" "ORGB-PRODUCT"
echo "-- Org admin A: cannot access org-b marketplace by ID"
code="$(curl -sS -o /dev/null -w "%{http_code}" -b "$jar_a" -c "$jar_a" -H "X-Forwarded-Host: localhost:3000" -H "X-Forwarded-Port: 3000" "${BACKEND_BASE}/api/v1/admin/listings?marketplace_id=${mkt_b_id}")"
if [[ "$code" != "404" ]]; then
  echo "Expected 404 for cross-org marketplace access, got ${code}" >&2
  exit 1
fi

echo "-- Org admin A: switch tenant via port (org-b) denied"
assert_http_code_in "401,403" "${BACKEND_BASE}/api/v1/admin/context" "$jar_a" "localhost:3003"

echo "-- Org admin B: org-b allowed"
login_via_oidc "adminB@test.com" "localhost" "3003" "$jar_b" "$ADMINFRONT_B_BASE"
ctx="$(fetch_json "${BACKEND_BASE}/api/v1/admin/context" "$jar_b" "localhost:3003")"
assert_contains "$ctx" "\"slug\":\"org2\""
listings="$(fetch_json "${BACKEND_BASE}/api/v1/admin/listings" "$jar_b" "localhost:3003")"
assert_contains "$listings" "ORGB-PRODUCT"
assert_not_contains "$listings" "ORGA-PRODUCT"

echo "-- Org admin B: switch tenant via port (org-a) denied"
assert_http_code_in "401,403" "${BACKEND_BASE}/api/v1/admin/context" "$jar_b" "localhost:3000"

echo "-- Normal user denied"
if login_via_oidc "user@test.com" "localhost" "3000" "$jar_user_denied" "$ADMINFRONT_BASE"; then
  echo "Expected normal user to be denied for admin org login but login succeeded" >&2
  exit 1
fi

echo "-- Adminfront: redirect when unauthenticated"
code="$(curl -sS -o /dev/null -w "%{http_code}" "${ADMINFRONT_BASE}/dashboard")"
if [[ "$code" != "307" && "$code" != "302" ]]; then
  echo "Expected redirect when unauthenticated, got ${code}" >&2
  exit 1
fi

echo "-- Adminfront: /dashboard loads when authenticated (adminA)"
assert_http_code "200" "${ADMINFRONT_BASE}/dashboard" "$jar_a"

echo "-- Logout cycle: revoke session and re-login"
curl -sS -o /dev/null -b "$jar_a" -c "$jar_a" -X POST "${ADMINFRONT_BASE}/api/auth/logout"
code="$(curl -sS -o /dev/null -w "%{http_code}" -b "$jar_a" -c "$jar_a" -H "X-Forwarded-Host: localhost:3000" -H "X-Forwarded-Port: 3000" "${BACKEND_BASE}/api/v1/admin/context")"
if [[ "$code" != "401" ]]; then
  echo "Expected 401 after logout, got ${code}" >&2
  exit 1
fi
code="$(curl -sS -o /dev/null -w "%{http_code}" -b "$jar_a" "${ADMINFRONT_BASE}/dashboard")"
if [[ "$code" != "307" && "$code" != "302" ]]; then
  echo "Expected redirect after logout, got ${code}" >&2
  exit 1
fi
login_via_oidc "adminA@test.com" "localhost" "3000" "$jar_a" "$ADMINFRONT_BASE"
assert_http_code "200" "${BACKEND_BASE}/api/v1/admin/context" "$jar_a" "localhost:3000"

echo
echo "OK: RBAC + org isolation smoke test passed."
