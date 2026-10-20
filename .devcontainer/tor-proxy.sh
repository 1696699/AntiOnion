#!/usr/bin/env bash
set -euo pipefail

readonly VERSION="15.0.25"
readonly BUNDLE_DIR="${TOR_EXPERT_BUNDLE_DIR:-${HOME}/.local/share/anti-onion/tor-expert-bundle-${VERSION}}"
readonly TOR_BIN="${BUNDLE_DIR}/tor/tor"
readonly STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/anti-onion-tor"
readonly PORT="${TOR_SOCKS_PORT:-19050}"
readonly PID_FILE="${STATE_DIR}/tor.pid"
readonly LOG_FILE="${STATE_DIR}/tor.log"

usage() {
  printf 'Usage: %s {start|check|stop|status}\n' "$0" >&2
}

case "${1:-}" in
  start)
    if [[ ! -x "$TOR_BIN" ]]; then
      printf 'Tor is not installed at %s; rebuild the Codespace or run the installer.\n' "$TOR_BIN" >&2
      exit 1
    fi
    mkdir -p "$STATE_DIR"
    if [[ -f "$PID_FILE" ]]; then
      existing_pid="$(<"$PID_FILE")"
      if [[ "$existing_pid" =~ ^[0-9]+$ ]] && kill -0 "$existing_pid" 2>/dev/null; then
        printf 'Tor is already running (pid %s) on 127.0.0.1:%s\n' "$existing_pid" "$PORT"
        exit 0
      fi
      rm -f "$PID_FILE"
    fi
    "$TOR_BIN" \
      --SocksPort "127.0.0.1:${PORT}" \
      --DataDirectory "${STATE_DIR}/data" \
      --GeoIPFile "${BUNDLE_DIR}/data/geoip" \
      --GeoIPv6File "${BUNDLE_DIR}/data/geoip6" \
      --PidFile "$PID_FILE" \
      --RunAsDaemon 1 \
      --Log "notice file ${LOG_FILE}"
    printf 'Started Tor on 127.0.0.1:%s (pid %s). Run "%s check" to verify.\n' \
      "$PORT" "$(<"$PID_FILE")" "$0"
    ;;
  check)
    response="$(curl --fail --silent --show-error --connect-timeout 5 --max-time 120 \
      --retry 8 --retry-delay 3 --retry-all-errors \
      --socks5-hostname "127.0.0.1:${PORT}" \
      https://check.torproject.org/api/ip)"
    python3 -c "import json, sys; data = json.load(sys.stdin); print('IsTor={} IP={}'.format(data.get('IsTor'), data.get('IP'))); sys.exit(0 if data.get('IsTor') is True else 1)" <<<"$response"
    ;;
  stop)
    if [[ ! -f "$PID_FILE" ]]; then
      printf 'Tor is not running (no pid file).\n'
      exit 0
    fi
    pid="$(<"$PID_FILE")"
    if [[ ! "$pid" =~ ^[0-9]+$ ]] || ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$PID_FILE"
      printf 'Removed stale Tor pid file.\n'
      exit 0
    fi
    process_args="$(ps -p "$pid" -o args= || true)"
    if [[ "$process_args" != *"$TOR_BIN"* ]]; then
      printf 'Refusing to stop pid %s because it is not the expected Tor binary.\n' "$pid" >&2
      exit 1
    fi
    kill -TERM "$pid"
    rm -f "$PID_FILE"
    printf 'Stopped Tor (pid %s).\n' "$pid"
    ;;
  status)
    if [[ -f "$PID_FILE" ]]; then
      pid="$(<"$PID_FILE")"
      if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
        printf 'Tor process %s; SOCKS listener configured for 127.0.0.1:%s\n' "$pid" "$PORT"
        exit 0
      fi
    fi
    printf 'Tor is not running.\n'
    exit 1
    ;;
  *)
    usage
    exit 2
    ;;
esac