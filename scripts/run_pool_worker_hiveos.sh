#!/usr/bin/env bash
set -euo pipefail

# HACPool HiveOS launcher (binary distribution, no local build).
# Flow:
#   1) Download latest worker package ZIP (or use a provided URL)
#   2) Extract package
#   3) Start miner with command-line args (no config file)

log() { echo "[HACPool-worker] $*"; }
fail() { echo "[HACPool-worker] ERROR: $*" >&2; exit 1; }

# Required env vars
SERVER_ADDRESS="${SERVER_ADDRESS:-}"
REWARD_ADDRESS="${REWARD_ADDRESS:-}"

# Optional worker settings
WORKER_NAME="${WORKER_NAME:-}"
DEVICES="${DEVICES:-}" # optional; empty = all GPUs
EFFORT="${EFFORT:-}" # optional; if set must be 1..100
WORKER_EXTRA_ARGS="${WORKER_EXTRA_ARGS:-}"

# Optional runtime paths
APP_DIR="${APP_DIR:-/hive/custom/HACPool-worker}"
WORKER_LOG_PATH="${WORKER_LOG_PATH:-${APP_DIR}/worker.log}"
ZIP_PATH="${ZIP_PATH:-${APP_DIR}/hacpool-worker.zip}"

# Optional release source
# Example:
#   HACPOOL_WORKER_URL="https://github.com/HacashCommunity/HACPool/releases/download/v0.1.0/HACPool-worker-hiveos-v0.1.0.zip"
HACPOOL_WORKER_URL="${HACPOOL_WORKER_URL:-}"

[[ -n "${SERVER_ADDRESS}" ]] || fail "SERVER_ADDRESS is required (example: pool.hacash.community:3333)"
[[ -n "${REWARD_ADDRESS}" ]] || fail "REWARD_ADDRESS is required"
if [[ -n "${EFFORT}" ]]; then
  [[ "${EFFORT}" =~ ^[0-9]+$ ]] || fail "EFFORT must be an integer 1..100"
  (( EFFORT >= 1 && EFFORT <= 100 )) || fail "EFFORT out of range (1..100)"
fi

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
[[ -f "${WORKER_BIN}" ]] || fail "miner binary not found after unzip: ${WORKER_BIN}"
chmod +x "${WORKER_BIN}"
WORKER_BIN_NAME="$(basename "${WORKER_BIN}")"
pkill -f "/${WORKER_BIN_NAME}" || true

log "starting worker..."
cd "${APP_DIR}"
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

nohup "${worker_cmd[@]}" > "${WORKER_LOG_PATH}" 2>&1 &
sleep 1

if pgrep -f "/${WORKER_BIN_NAME}" >/dev/null 2>&1; then
  log "worker started. Log: ${WORKER_LOG_PATH}"
  tail -n 30 "${WORKER_LOG_PATH}" || true
else
  fail "worker process did not stay running (check ${WORKER_LOG_PATH})"
fi
