#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_LOG_DIR="/workspace/HACPool-worker"
BOOTSTRAP_LOG_PATH="${BOOTSTRAP_LOG_DIR}/bootstrap.log"
mkdir -p "${BOOTSTRAP_LOG_DIR}"
exec > >(tee -a "${BOOTSTRAP_LOG_PATH}") 2>&1

if [[ "${DEBUG_BOOTSTRAP:-0}" == "1" ]]; then
  set -x
fi

trap 'echo "[bootstrap] ERROR on line $LINENO"' ERR

echo "[bootstrap] Starting HACPool Vast bootstrap..."
echo "[bootstrap] Log file: ${BOOTSTRAP_LOG_PATH}"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends curl unzip ca-certificates

: "${SERVER_ADDRESS:?Missing SERVER_ADDRESS (example: pool.hacash.community:3333)}"
: "${REWARD_ADDRESS:?Missing REWARD_ADDRESS}"

WORKER_NAME="${WORKER_NAME:-}"
DEVICES="${DEVICES:-}"   # empty = all GPUs
EFFORT="${EFFORT:-}"     # optional; if set must be 1..100
WORKER_EXTRA_ARGS="${WORKER_EXTRA_ARGS:-}"

# Validate optional effort only when provided
if [[ -n "${EFFORT}" ]]; then
  [[ "${EFFORT}" =~ ^[0-9]+$ ]] || { echo "[bootstrap] ERROR: EFFORT must be an integer 1..100"; exit 1; }
  (( EFFORT >= 1 && EFFORT <= 100 )) || { echo "[bootstrap] ERROR: EFFORT out of range (1..100)"; exit 1; }
fi

# Optional fixed release URL:
# HACPOOL_WORKER_URL="https://github.com/HacashCommunity/HACPool/releases/download/v0.1.0/HACPool-worker-ubuntu-v0.1.0.zip"
HACPOOL_WORKER_URL="${HACPOOL_WORKER_URL:-}"

APP_DIR="/workspace/HACPool-worker"
ZIP_PATH="/workspace/hacpool-worker.zip"
LOG_PATH="$APP_DIR/worker.log"

mkdir -p "$APP_DIR"
cd /workspace

if [[ -z "$HACPOOL_WORKER_URL" ]]; then
  HACPOOL_WORKER_URL="$(curl -fsSL https://api.github.com/repos/HacashCommunity/HACPool/releases/latest \
    | grep browser_download_url \
    | cut -d '"' -f 4 \
    | grep 'HACPool-worker-ubuntu-v.*\.zip' \
    | head -n1)"
fi

if [[ -z "$HACPOOL_WORKER_URL" ]]; then
  echo "ERROR: Could not resolve HACPOOL_WORKER_URL"
  exit 1
fi

echo "Downloading: $HACPOOL_WORKER_URL"
curl -fL "$HACPOOL_WORKER_URL" -o "$ZIP_PATH"

rm -rf "$APP_DIR"/*
set +e
unzip -o "$ZIP_PATH" -d "$APP_DIR"
UNZIP_RC=$?
set -e
if [[ "$UNZIP_RC" -gt 1 ]]; then
  echo "[bootstrap] ERROR: unzip failed with code $UNZIP_RC"
  exit "$UNZIP_RC"
fi
if [[ "$UNZIP_RC" -eq 1 ]]; then
  echo "[bootstrap] unzip completed with warnings (code 1); continuing"
fi
WORKER_BIN="$APP_DIR/HACPool-worker"
[[ -f "$WORKER_BIN" ]] || { echo "[bootstrap] ERROR: miner binary not found after unzip (expected $WORKER_BIN)"; exit 1; }
chmod +x "$WORKER_BIN"
WORKER_BIN_NAME="$(basename "$WORKER_BIN")"
echo "[bootstrap] Package extracted to: $APP_DIR"

pkill -f "/${WORKER_BIN_NAME}" || true

cd "$APP_DIR"
pool_url="${SERVER_ADDRESS}"
if [[ "${pool_url}" != *"://"* ]]; then
  pool_url="stratum+tcp://${pool_url}"
fi

worker_user="${REWARD_ADDRESS}"
if [[ -n "${WORKER_NAME}" ]]; then
  worker_user="${REWARD_ADDRESS}.${WORKER_NAME}"
fi

worker_cmd=("${WORKER_BIN}" -o "${pool_url}" -u "${worker_user}")
if [[ -n "${EFFORT}" ]]; then
  worker_cmd+=(--effort "${EFFORT}")
fi
if [[ -n "${DEVICES}" ]]; then
  worker_cmd+=(--devices "${DEVICES}")
fi
if [[ -n "${WORKER_EXTRA_ARGS}" ]]; then
  # shellcheck disable=SC2206
  extra_args=( ${WORKER_EXTRA_ARGS} )
  worker_cmd+=("${extra_args[@]}")
fi

nohup "${worker_cmd[@]}" > "$LOG_PATH" 2>&1 &
sleep 1
if pgrep -f "/${WORKER_BIN_NAME}" >/dev/null 2>&1; then
  echo "[bootstrap] Worker started. Worker log: $LOG_PATH"
  tail -n 30 "$LOG_PATH" || true
else
  echo "[bootstrap] ERROR: worker process did not stay running."
  echo "[bootstrap] Showing worker log tail:"
  tail -n 80 "$LOG_PATH" || true
  exit 1
fi
