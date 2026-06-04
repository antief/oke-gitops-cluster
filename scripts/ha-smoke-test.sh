#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

URL="${WHOAMI_URL:-https://whoami.hanhela.org/}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-1}"
CONNECT_TIMEOUT_SECONDS="${CONNECT_TIMEOUT_SECONDS:-2}"
MAX_TIME_SECONDS="${MAX_TIME_SECONDS:-5}"
FAILURES=0
REQUESTS=0

usage() {
  cat <<'USAGE'
Usage:
  WHOAMI_URL=https://whoami.example.com/ ./scripts/ha-smoke-test.sh

Continuously calls the whoami endpoint and prints timestamp, HTTP status,
latency and the backend hostname returned by whoami.

Environment variables:
  WHOAMI_URL                 URL to test. Default: https://whoami.hanhela.org/
  INTERVAL_SECONDS           Delay between requests. Default: 1
  CONNECT_TIMEOUT_SECONDS    curl connect timeout. Default: 2
  MAX_TIME_SECONDS           curl max request time. Default: 5
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

command -v curl >/dev/null 2>&1 || {
  echo "Missing required command: curl" >&2
  exit 1
}

cleanup() {
  printf '\nRequests: %s  Failures: %s\n' "$REQUESTS" "$FAILURES" >&2
}
trap cleanup EXIT

printf 'Testing %s every %ss. Press Ctrl+C to stop.\n' "$URL" "$INTERVAL_SECONDS" >&2

while true; do
  REQUESTS=$((REQUESTS + 1))
  tmp_body="$(mktemp)"

  result="$({
    curl \
      --silent \
      --show-error \
      --location \
      --connect-timeout "$CONNECT_TIMEOUT_SECONDS" \
      --max-time "$MAX_TIME_SECONDS" \
      --output "$tmp_body" \
      --write-out '%{http_code} %{time_total}' \
      "$URL"
  } 2>&1)" || {
    FAILURES=$((FAILURES + 1))
    printf '%s FAIL request_error=%q\n' "$(date -Is)" "$result"
    rm -f "$tmp_body"
    sleep "$INTERVAL_SECONDS"
    continue
  }

  http_code="${result%% *}"
  latency="${result#* }"
  hostname="$(awk -F': ' 'tolower($1) == "hostname" { print $2; exit }' "$tmp_body" | tr -d '\r')"
  rm -f "$tmp_body"

  if [[ "$http_code" != "200" ]]; then
    FAILURES=$((FAILURES + 1))
    printf '%s FAIL http=%s latency=%ss backend=%s\n' "$(date -Is)" "$http_code" "$latency" "${hostname:-unknown}"
  else
    printf '%s OK   http=%s latency=%ss backend=%s\n' "$(date -Is)" "$http_code" "$latency" "${hostname:-unknown}"
  fi

  sleep "$INTERVAL_SECONDS"
done
