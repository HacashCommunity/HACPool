# HACPool Worker on HiveOS

This guide runs `HACPool-worker` on HiveOS using a prebuilt binary package.

Script:
- `run_pool_worker_hiveos.sh` (standalone; no repo clone required)

What it does:
1. Downloads the latest HiveOS worker ZIP from GitHub Releases (or a fixed URL).
2. Extracts it locally.
3. Generates `HACPool-worker.ini`.
4. Starts the worker process.

## Quick Start

Recommended (without cloning repository):

```bash
curl -fsSL https://raw.githubusercontent.com/HacashCommunity/HACPool/refs/heads/main/scripts/run_pool_worker_hiveos.sh -o run_pool_worker_hiveos.sh
chmod +x ./run_pool_worker_hiveos.sh

SERVER_ADDRESS="pool.hacash.community:7001" \
REWARD_ADDRESS="YOUR_HAC_ADDRESS" \
WORKER_NAME="rig001" \
MINING_MODE="gpu" \
./run_pool_worker_hiveos.sh
```

## Required Variables

- `SERVER_ADDRESS` (example: `pool.hacash.community:7001`)
- `REWARD_ADDRESS`

## Optional Variables

- `WORKER_NAME` (default: empty)
- `MINING_MODE` = `cpu` or `gpu` (default: `gpu`)
- `CPU_THREADS` (CPU mode only; default: `nproc`)
- `GPU_EFFORT_PERCENT` (GPU mode only; `1..100`, default `100`)
- `OPENCL_DIR` (default: `opencl`)
- `OPENCL_PLATFORM_ID` (default: `0`)
- `OPENCL_DEVICE_ID` (optional; omit to use all GPUs)
- `HACPOOL_WORKER_URL` (optional fixed release ZIP URL)

## Paths

- `APP_DIR` (default: `/hive/custom/HACPool-worker`)
- `WORKER_CONFIG_PATH` (default: `${APP_DIR}/HACPool-worker.ini`)
- `WORKER_LOG_PATH` (default: `${APP_DIR}/worker.log`)
- `ZIP_PATH` (default: `${APP_DIR}/hacpool-worker.zip`)

## Requirements

- `curl`
- `unzip`
