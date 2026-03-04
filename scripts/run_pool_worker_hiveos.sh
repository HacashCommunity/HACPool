#!/usr/bin/env bash
set -euo pipefail

# HACPool HiveOS launcher (binary distribution, no local build).
# Flow:
#   1) Download latest worker package ZIP (or use a provided URL)
#   2) Extract package
#   3) Generate HACPool-worker.ini from env vars
#   4) Start HACPool-worker

log() { echo "[HACPool-worker] $*"; }
fail() { echo "[HACPool-worker] ERROR: $*" >&2; exit 1; }

# Required env vars
SERVER_ADDRESS="${SERVER_ADDRESS:-}"
REWARD_ADDRESS="${REWARD_ADDRESS:-}"

# Optional worker settings
WORKER_NAME="${WORKER_NAME:-}"
MINING_MODE="${MINING_MODE:-gpu}"       # cpu | gpu
CPU_THREADS="${CPU_THREADS:-$(nproc)}"  # cpu mode only
GPU_EFFORT_PERCENT="${GPU_EFFORT_PERCENT:-100}"
OPENCL_DIR="${OPENCL_DIR:-opencl}"
OPENCL_PLATFORM_ID="${OPENCL_PLATFORM_ID:-0}"
OPENCL_DEVICE_ID="${OPENCL_DEVICE_ID:-}" # optional; empty = all GPUs

# Optional runtime paths
APP_DIR="${APP_DIR:-/hive/custom/HACPool-worker}"
WORKER_CONFIG_PATH="${WORKER_CONFIG_PATH:-${APP_DIR}/HACPool-worker.ini}"
WORKER_LOG_PATH="${WORKER_LOG_PATH:-${APP_DIR}/worker.log}"
ZIP_PATH="${ZIP_PATH:-${APP_DIR}/hacpool-worker.zip}"

# Optional release source
# Example:
#   HACPOOL_WORKER_URL="https://github.com/HacashCommunity/HACPool/releases/download/v0.1.0/HACPool-worker-hiveos-v0.1.0.zip"
HACPOOL_WORKER_URL="${HACPOOL_WORKER_URL:-}"

[[ -n "${SERVER_ADDRESS}" ]] || fail "SERVER_ADDRESS is required (example: pool.hacash.community:7001)"
[[ -n "${REWARD_ADDRESS}" ]] || fail "REWARD_ADDRESS is required"
[[ "${MINING_MODE}" == "cpu" || "${MINING_MODE}" == "gpu" ]] || fail "MINING_MODE must be cpu or gpu"
[[ "${GPU_EFFORT_PERCENT}" =~ ^[0-9]+$ ]] || fail "GPU_EFFORT_PERCENT must be an integer 1..100"
(( GPU_EFFORT_PERCENT >= 1 && GPU_EFFORT_PERCENT <= 100 )) || fail "GPU_EFFORT_PERCENT out of range (1..100)"

command -v curl >/dev/null 2>&1 || fail "curl not found"
command -v unzip >/dev/null 2>&1 || fail "unzip not found"

mkdir -p "${APP_DIR}"

if [[ -z "${HACPOOL_WORKER_URL}" ]]; then
  HACPOOL_WORKER_URL="$(curl -fsSL https://api.github.com/repos/HacashCommunity/HACPool/releases/latest \
    | grep browser_download_url \
    | cut -d '"' -f 4 \
    | grep 'HACPool-worker-hiveos-v.*\.zip' \
    | head -n1)"
fi

[[ -n "${HACPOOL_WORKER_URL}" ]] || fail "Could not resolve HACPOOL_WORKER_URL for latest release"

log "downloading package: ${HACPOOL_WORKER_URL}"
curl -fL "${HACPOOL_WORKER_URL}" -o "${ZIP_PATH}"

log "extracting package to ${APP_DIR}"
set +e
unzip -o "${ZIP_PATH}" -d "${APP_DIR}"
UNZIP_RC=$?
set -e
if [[ "${UNZIP_RC}" -gt 1 ]]; then
  fail "unzip failed with code ${UNZIP_RC}"
fi

WORKER_BIN="${APP_DIR}/HACPool-worker"
[[ -f "${WORKER_BIN}" ]] || fail "worker binary not found after unzip: ${WORKER_BIN}"
chmod +x "${WORKER_BIN}"

if [[ "${MINING_MODE}" == "gpu" && "${OPENCL_DIR}" == "opencl" && ! -d "${APP_DIR}/opencl" ]]; then
  fail "GPU mode selected but opencl directory not found in package (${APP_DIR}/opencl)"
fi

{
  echo "server_address = \"${SERVER_ADDRESS}\""
  echo "reward_address = \"${REWARD_ADDRESS}\""
  echo "worker_name = \"${WORKER_NAME}\""
  echo ""
  echo "mining_mode = \"${MINING_MODE}\""
  if [[ "${MINING_MODE}" == "cpu" ]]; then
    echo "cpu_threads = ${CPU_THREADS}"
  else
    echo "opencl_dir = \"${OPENCL_DIR}\""
    echo "opencl_platform_id = ${OPENCL_PLATFORM_ID}"
    if [[ -n "${OPENCL_DEVICE_ID}" ]]; then
      echo "opencl_device_id = ${OPENCL_DEVICE_ID}"
    fi
    echo "gpu_effort_percent = ${GPU_EFFORT_PERCENT}"
  fi
} > "${WORKER_CONFIG_PATH}"

grep -q "reward_address = \"${REWARD_ADDRESS}\"" "${WORKER_CONFIG_PATH}" || {
  fail "generated config does not contain REWARD_ADDRESS"
}

pkill -f "/HACPool-worker" || true

log "starting worker..."
cd "${APP_DIR}"
nohup "${WORKER_BIN}" --config "${WORKER_CONFIG_PATH}" > "${WORKER_LOG_PATH}" 2>&1 &
sleep 1

if pgrep -f "/HACPool-worker" >/dev/null 2>&1; then
  log "worker started. Log: ${WORKER_LOG_PATH}"
  tail -n 30 "${WORKER_LOG_PATH}" || true
else
  fail "worker process did not stay running (check ${WORKER_LOG_PATH})"
fi
