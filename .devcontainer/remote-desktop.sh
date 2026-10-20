#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VNC_DISPLAY=":1"
readonly VNC_PORT=5901
readonly WEB_PORT="${NOVNC_PORT:-6080}"
readonly VNC_PASSWORD_FILE="${HOME}/.vnc/passwd"
readonly STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/anti-onion-desktop"
readonly WEBSOCKIFY_PID_FILE="${STATE_DIR}/websockify.pid"
readonly WEBSOCKIFY_LOG="${STATE_DIR}/websockify.log"

usage() {
  printf 'Usage: %s {start|stop|status}\n' "$0" >&2
}

case "${1:-}" in
  start)
    if [[ ! -s "$VNC_PASSWORD_FILE" ]]; then
      printf 'Set a VNC password interactively first with: mkdir -p "$HOME/.vnc" && vncpasswd "$VNC_PASSWORD_FILE"\n' >&2
      exit 1
    fi
    if [[ ! -f /usr/share/novnc/vnc.html ]]; then
      printf 'noVNC web files are missing; rebuild the Dev Container.\n' >&2
      exit 1
    fi
    mkdir -p "$STATE_DIR"
    chmod 700 "$HOME/.vnc"

    if ! vncserver -list | grep -Eq '^[[:space:]]*:?[[:space:]]*1([[:space:]]|$)'; then
      vncserver "$VNC_DISPLAY" \
        -localhost yes \
        -geometry "${VNC_GEOMETRY:-1280x800}" \
        -depth 24 \
        -SecurityTypes VncAuth \
        -rfbauth "$VNC_PASSWORD_FILE" \
        -xstartup "${SCRIPT_DIR}/xstartup"
    fi

    if [[ -f "$WEBSOCKIFY_PID_FILE" ]]; then
      existing_pid="$(<"$WEBSOCKIFY_PID_FILE")"
      if [[ "$existing_pid" =~ ^[0-9]+$ ]] && kill -0 "$existing_pid" 2>/dev/null \
        && [[ "$(ps -p "$existing_pid" -o args= || true)" == *websockify* ]]; then
        printf 'Remote desktop is already available on private port %s.\n' "$WEB_PORT"
        exit 0
      fi
      rm -f "$WEBSOCKIFY_PID_FILE"
    fi

    websockify --web=/usr/share/novnc \
      "127.0.0.1:${WEB_PORT}" "127.0.0.1:${VNC_PORT}" \
      >"$WEBSOCKIFY_LOG" 2>&1 &
    websockify_pid="$!"
    printf '%s\n' "$websockify_pid" >"$WEBSOCKIFY_PID_FILE"
    if ! curl --fail --silent --connect-timeout 1 --max-time 3 \
      --retry 10 --retry-delay 1 --retry-all-errors \
      --output /dev/null "http://127.0.0.1:${WEB_PORT}/vnc.html"; then
      if kill -0 "$websockify_pid" 2>/dev/null; then
        kill -TERM "$websockify_pid"
      fi
      rm -f "$WEBSOCKIFY_PID_FILE"
      vncserver -kill "$VNC_DISPLAY" >/dev/null 2>&1 || true
      printf 'noVNC failed to start. See %s\n' "$WEBSOCKIFY_LOG" >&2
      exit 1
    fi
    printf 'Remote desktop started. Open the private forwarded port %s, use /vnc.html, and enter your VNC password.\n' "$WEB_PORT"
    ;;
  stop)
    if [[ -f "$WEBSOCKIFY_PID_FILE" ]]; then
      pid="$(<"$WEBSOCKIFY_PID_FILE")"
      if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
        process_args="$(ps -p "$pid" -o args= || true)"
        if [[ "$process_args" == *websockify* ]]; then
          kill -TERM "$pid"
        else
          printf 'Refusing to stop pid %s because it is not websockify.\n' "$pid" >&2
          exit 1
        fi
      fi
      rm -f "$WEBSOCKIFY_PID_FILE"
    fi
    vncserver -kill "$VNC_DISPLAY" >/dev/null 2>&1 || true
    printf 'Remote desktop stopped.\n'
    ;;
  status)
    if [[ -f "$WEBSOCKIFY_PID_FILE" ]]; then
      pid="$(<"$WEBSOCKIFY_PID_FILE")"
      if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null \
        && [[ "$(ps -p "$pid" -o args= || true)" == *websockify* ]] \
        && vncserver -list | grep -Eq '^[[:space:]]*:?[[:space:]]*1([[:space:]]|$)'; then
        printf 'Remote desktop is running on private port %s.\n' "$WEB_PORT"
        exit 0
      fi
    fi
    printf 'Remote desktop is not running.\n'
    exit 1
    ;;
  *)
    usage
    exit 2
    ;;
esac