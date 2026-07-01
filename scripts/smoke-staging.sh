#!/usr/bin/env bash
# Smoke test: staging click → S2S registration + deposit with dashboard API key.
# Usage:
#   export S2S_API_KEY="s2s_…"   # from ads-staging Campaigns → S2S keys
#   ./scripts/smoke-staging.sh
# Optional:
#   TRACKER_ORIGIN=https://ads-staging.datavela.io CAMP=camp_test01 CRID=cr88992 ./scripts/smoke-staging.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${TRACKER_ORIGIN:-https://ads-staging.datavela.io}"
BASE="${BASE%/}"
CAMP="${CAMP:-camp_test01}"
CRID="${CRID:-cr88992}"
KEY="${S2S_API_KEY:-}"

if [ -z "$KEY" ]; then
  echo "FAIL: set S2S_API_KEY (staging key from Campaigns → S2S API keys)" >&2
  exit 1
fi

MOBILE_UA="Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36"
KIT_VERSION="$(cat "$ROOT/VERSION" | tr -d '[:space:]')"

echo "==> Kit v${KIT_VERSION} → ${BASE}"
echo "==> Health"
curl -sS "${BASE}/api/health" | grep -q '"ok":true' || { echo "FAIL: health"; exit 1; }

echo "==> Click (get clk_id)"
HEADERS="$(mktemp)"
curl -sS -D "$HEADERS" -o /dev/null -A "$MOBILE_UA" \
  "${BASE}/c/${CAMP}?source=meta&crid=${CRID}&fbclid=kit_smoke"
CLK="$(grep -i 'set-cookie: clk_id=' "$HEADERS" | sed -E 's/.*clk_id=([^;]+).*/\1/' | tr -d '\r' || true)"
rm -f "$HEADERS"
if [ -z "$CLK" ]; then
  echo "FAIL: no clk_id cookie — check campaign id ${CAMP} and crid ${CRID}" >&2
  exit 1
fi
echo "clk_id=${CLK}"

post_event() {
  local event="$1"
  local body="$2"
  echo "==> S2S ${event}"
  local resp
  resp="$(curl -sS -w "\n%{http_code}" -X POST "${BASE}/api/v1/s2s/event" \
    -H "Authorization: Bearer ${KEY}" \
    -H "Content-Type: application/json" \
    -d "$body")"
  local code="${resp##*$'\n'}"
  local json="${resp%$'\n'*}"
  echo "$json"
  if [ "$code" != "200" ]; then
    echo "FAIL: HTTP ${code}" >&2
    exit 1
  fi
  echo "$json" | grep -q '"attributed":true' || {
    echo "WARN: attributed=false — clk_id may not match session (still logged)"
  }
}

post_event registration "{\"event\":\"registration\",\"clk_id\":\"${CLK}\",\"properties\":{\"user_id\":\"kit_smoke_1\",\"source\":\"gbo-money-site-s2s-kit\"}}"
post_event deposit "{\"event\":\"deposit\",\"clk_id\":\"${CLK}\",\"value\":50,\"currency\":\"USD\",\"properties\":{\"order_id\":\"kit_smoke_ord_1\",\"payment_method\":\"test\"}}"

echo "==> PASS — verify dashboard (Staging): crid ${CRID} +1 reg, +1 dep"
echo "    ${BASE}/dashboard"
