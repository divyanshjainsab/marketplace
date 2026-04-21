#!/usr/bin/env bash
set -euo pipefail

BACKEND_BASE="${BACKEND_BASE:-http://localhost:3015}"
SSO_BASE="${SSO_BASE:-http://localhost:3001}"
PASSWORD="${SEED_PASSWORD:-Password123!}"
EMAIL="${TWO_FACTOR_EMAIL:-superadmin@test.com}"
SECRET="${TWO_FACTOR_SECRET:-JBSWY3DPEHPK3PXP}"

tmpdir="$(mktemp -d)"
cleanup() {
  docker compose exec -T sso bundle exec rails runner \
    "user = User.find_by!(email: \"${EMAIL}\"); user.update!(otp_required_for_login: false, otp_secret: nil, otp_backup_codes: [])" \
    >/dev/null
  rm -rf "$tmpdir"
}
trap cleanup EXIT

docker compose exec -T sso bundle exec rails runner \
  "user = User.find_by!(email: \"${EMAIL}\"); user.update!(email_verified: true, otp_required_for_login: true, otp_secret: \"${SECRET}\", otp_backup_codes: [])" \
  >/dev/null

jar="$tmpdir/twofactor.cookies"
start_headers="$tmpdir/start.headers"
otp_headers="$tmpdir/otp.headers"

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
    --data-urlencode "user[email]=${EMAIL}" \
    --data-urlencode "user[password]=${PASSWORD}"
)"

two_factor_required="$(python3 -c 'import json,sys; print("true" if json.load(sys.stdin).get("two_factor_required") else "false")' <<<"$login_json")"
if [[ "$two_factor_required" != "true" ]]; then
  echo "Expected two_factor_required=true but got: $login_json" >&2
  exit 1
fi

otp_code="$(docker compose exec -T sso bundle exec rails runner "puts ROTP::TOTP.new(\"${SECRET}\").now" | tr -d '\r' | tail -n1)"

curl -sS -D "$otp_headers" -o /dev/null \
  -c "$jar" -b "$jar" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST "${SSO_BASE}/users/otp_verify" \
  --data "{\"otp_attempt\":\"${otp_code}\"}"

otp_redirect="$(awk -F': ' 'tolower($1)=="location"{print $2}' "$otp_headers" | tr -d '\r' | tail -n1)"
if [[ -z "$otp_redirect" ]]; then
  echo "Missing backend callback redirect after OTP verification" >&2
  exit 1
fi

curl -sS -D /dev/null -o /dev/null -c "$jar" -b "$jar" "$otp_redirect"

if ! grep -q "mp_access" "$jar"; then
  echo "2FA callback did not establish a backend session" >&2
  exit 1
fi

echo "TWO_FACTOR_REQUIRED=${two_factor_required}"
echo "OTP_REDIRECT=${otp_redirect}"
echo "SESSION_ESTABLISHED=true"
