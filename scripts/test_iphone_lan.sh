#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BE_PORT="${BE_PORT:-3000}"
FE_PORT="${FE_PORT:-3001}"
NETWORK_IFACE="${NETWORK_IFACE:-}"
SKIP_INSTALL="${SKIP_INSTALL:-0}"
MAC_IP="${MAC_IP:-}"
DEBUG_MODE="${DEBUG_MODE:-0}"

# Determine Flutter run mode
if [[ "${DEBUG_MODE}" == "1" ]]; then
  FLUTTER_MODE="--debug"
  MODE_LABEL="DEBUG (hot reload enabled)"
else
  FLUTTER_MODE="--profile"
  MODE_LABEL="PROFILE (no hot reload)"
fi

if [[ -z "${MAC_IP}" ]]; then
  if [[ -z "${NETWORK_IFACE}" ]]; then
    NETWORK_IFACE="$(route get default 2>/dev/null | awk '/interface:/{print $2}' | head -n1 || true)"
  fi
  if [[ -z "${NETWORK_IFACE}" ]]; then
    NETWORK_IFACE="en0"
  fi
  MAC_IP="$(ipconfig getifaddr "${NETWORK_IFACE}" 2>/dev/null || true)"
fi

if [[ -z "${MAC_IP}" ]]; then
  echo "Could not detect LAN IP."
  echo "Try: NETWORK_IFACE=en0 make iphone"
  echo "Or:  MAC_IP=192.168.x.x make iphone"
  exit 1
fi

API_BASE_URL="http://${MAC_IP}:${BE_PORT}"
FRONTEND_URL="http://${MAC_IP}:${FE_PORT}"

if [[ "${SKIP_INSTALL}" != "1" ]]; then
  echo "Installing dependencies..."
  (cd "${ROOT_DIR}/apps/backend" && npm install)
  (cd "${ROOT_DIR}/apps/frontend" && flutter pub get)
fi

echo ""
echo "LAN setup"
echo "- Interface: ${NETWORK_IFACE}"
echo "- Mac IP:    ${MAC_IP}"
echo "- Backend:   ${API_BASE_URL}"
echo "- Frontend:  ${FRONTEND_URL}"
echo "- Mode:      ${MODE_LABEL}"
echo ""

if command -v qrencode >/dev/null 2>&1; then
  echo "Scan this QR on iPhone (Safari):"
  qrencode -t ANSIUTF8 "${FRONTEND_URL}"
else
  echo "QR not available (install with: brew install qrencode)"
fi

echo ""
echo "Starting backend and frontend..."
echo "Press Ctrl+C to stop both."
echo ""

cleanup() {
  local exit_code=$?
  trap - EXIT INT TERM
  if [[ -n "${BE_PID:-}" ]] && kill -0 "${BE_PID}" >/dev/null 2>&1; then
    kill "${BE_PID}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${FE_PID:-}" ]] && kill -0 "${FE_PID}" >/dev/null 2>&1; then
    kill "${FE_PID}" >/dev/null 2>&1 || true
  fi
  wait >/dev/null 2>&1 || true
  exit "${exit_code}"
}

trap cleanup EXIT INT TERM

(
  cd "${ROOT_DIR}/apps/backend"
  PORT="${BE_PORT}" npm run dev 2>&1 | sed 's/^/[BE] /'
) &
BE_PID=$!

cd "${ROOT_DIR}/apps/frontend"
flutter run -d web-server \
  ${FLUTTER_MODE} \
  --web-hostname 0.0.0.0 \
  --web-port "${FE_PORT}" \
  --dart-define=API_BASE_URL="${API_BASE_URL}"
