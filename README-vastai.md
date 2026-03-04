# HACPool Worker on Vast.ai

This guide runs `HACPool-worker` on Vast.ai at instance startup.

Script:
- `scripts/start_vast_worker.sh`

What it does:
1. Installs minimal runtime packages.
2. Downloads the latest Ubuntu worker ZIP from GitHub Releases (or a fixed URL).
3. Extracts files and generates `HACPool-worker.ini`.
4. Starts worker in background and writes logs.

## Template Description

`HACPool worker auto-bootstrap (download latest release, generate config, auto-start)`

## Recommended Base Image

- `nvidia/cuda:12.2.0-runtime-ubuntu22.04`

## Entry Script (On-start, <=1024 chars)

```bash
#!/usr/bin/env bash
set -euo pipefail
curl -fsSL https://raw.githubusercontent.com/HacashCommunity/HACPool/refs/heads/main/scripts/start_vast_worker.sh | bash
```

## Required Variables

- `SERVER_ADDRESS` = `pool.hacash.community:7001`
- `REWARD_ADDRESS` = `YOUR_HAC_ADDRESS`

## Optional Variables

- `WORKER_NAME` (default: empty)
- `MINING_MODE` (`gpu` default, or `cpu`)
- `CPU_THREADS` (CPU mode only)
- `GPU_EFFORT_PERCENT` (`1..100`, default `100`)
- `OPENCL_PLATFORM_ID` (default `0`)
- `OPENCL_DEVICE_ID` (optional)
- `OPENCL_DIR` (default `opencl`)
- `HACPOOL_WORKER_URL` (optional fixed release ZIP URL)

## Logs

- Bootstrap: `/workspace/HACPool-worker/bootstrap.log`
- Worker: `/workspace/HACPool-worker/worker.log`
