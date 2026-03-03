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
apt-get install -y --no-install-recommends curl unzip ca-certificates ocl-icd-opencl-dev

: "${SERVER_ADDRESS:?Missing SERVER_ADDRESS (example: pool.hacash.community:7001)}"
: "${REWARD_ADDRESS:?Missing REWARD_ADDRESS}"

WORKER_NAME="${WORKER_NAME:-}"
MINING_MODE="${MINING_MODE:-gpu}"          # gpu | cpu
CPU_THREADS="${CPU_THREADS:-$(nproc)}"     # used when MINING_MODE=cpu
GPU_EFFORT_PERCENT="${GPU_EFFORT_PERCENT:-100}"
OPENCL_DIR="${OPENCL_DIR:-opencl}"
OPENCL_PLATFORM_ID="${OPENCL_PLATFORM_ID:-0}"
OPENCL_DEVICE_ID="${OPENCL_DEVICE_ID:-}"   # empty = all GPUs

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
[[ -f "$APP_DIR/HACPool-worker" ]] || { echo "[bootstrap] ERROR: binary not found after unzip"; exit 1; }
chmod +x "$APP_DIR/HACPool-worker"
echo "[bootstrap] Package extracted to: $APP_DIR"

cat > "$APP_DIR/HACPool-worker.ini" <<EOF
server_address = "${SERVER_ADDRESS}"
reward_address = "${REWARD_ADDRESS}"
worker_name = "${WORKER_NAME}"

mining_mode = "${MINING_MODE}"
EOF

if [[ "$MINING_MODE" == "cpu" ]]; then
  cat >> "$APP_DIR/HACPool-worker.ini" <<EOF
cpu_threads = ${CPU_THREADS}
EOF
else
  cat >> "$APP_DIR/HACPool-worker.ini" <<EOF
opencl_dir = "${OPENCL_DIR}"
opencl_platform_id = ${OPENCL_PLATFORM_ID}
gpu_effort_percent = ${GPU_EFFORT_PERCENT}
EOF
  if [[ -n "$OPENCL_DEVICE_ID" ]]; then
    echo "opencl_device_id = ${OPENCL_DEVICE_ID}" >> "$APP_DIR/HACPool-worker.ini"
  fi
fi

grep -q "reward_address = \"${REWARD_ADDRESS}\"" "$APP_DIR/HACPool-worker.ini" || {
  echo "[bootstrap] ERROR: generated ini does not contain REWARD_ADDRESS"
  sed -n '1,60p' "$APP_DIR/HACPool-worker.ini" || true
  exit 1
}

pkill -f "/workspace/HACPool-worker/HACPool-worker" || true

cd "$APP_DIR"
nohup ./HACPool-worker --config HACPool-worker.ini > "$LOG_PATH" 2>&1 &
sleep 1
if pgrep -f "/workspace/HACPool-worker/HACPool-worker" >/dev/null 2>&1; then
  echo "[bootstrap] Worker started. Worker log: $LOG_PATH"
  tail -n 30 "$LOG_PATH" || true
else
  echo "[bootstrap] ERROR: worker process did not stay running."
  echo "[bootstrap] Showing worker log tail:"
  tail -n 80 "$LOG_PATH" || true
  exit 1
fi
