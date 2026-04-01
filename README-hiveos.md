# HACPool Worker on HiveOS

This guide runs `HACPool-worker` on HiveOS using a prebuilt binary package.

Script:
- `run_pool_worker_hiveos.sh` (standalone; no repo clone required)

What it does:
1. Downloads the latest HiveOS worker ZIP from GitHub Releases (or a fixed URL).
2. Extracts it locally.
3. Starts `HACPool-worker` with command-line arguments (no config file).

## Quick Start

Recommended (without cloning repository):

```bash
curl -fsSL https://raw.githubusercontent.com/HacashCommunity/HACPool/refs/heads/main/scripts/run_pool_worker_hiveos.sh -o run_pool_worker_hiveos.sh
chmod +x ./run_pool_worker_hiveos.sh

SERVER_ADDRESS="pool.hacash.community:3333" \
REWARD_ADDRESS="YOUR_HAC_ADDRESS" \
WORKER_NAME="rig001" \
./run_pool_worker_hiveos.sh
```

## Required Variables

- `SERVER_ADDRESS` (example: `pool.hacash.community:3333`)
- `REWARD_ADDRESS`

## Optional Variables

- `WORKER_NAME` (default: empty)
- `EFFORT` (optional; if set, must be `1..100`)
- `DEVICES` (optional; omit to use all GPUs)
- `WORKER_EXTRA_ARGS` (optional; extra `HACPool-worker` flags)
- `HACPOOL_WORKER_URL` (optional fixed release ZIP URL)

## Paths

- `APP_DIR` (default: `/hive/custom/HACPool-worker`)
- `WORKER_LOG_PATH` (default: `${APP_DIR}/worker.log`)
- `ZIP_PATH` (default: `${APP_DIR}/hacpool-worker.zip`)

## Requirements

- `curl`
- `unzip`
