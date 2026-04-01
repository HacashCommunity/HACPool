# HACPool Worker on Vast.ai

This guide runs `HACPool-worker` on Vast.ai at instance startup.

Script:
- `scripts/start_vast_worker.sh`

What it does:
1. Installs minimal runtime packages.
2. Downloads the latest Ubuntu worker ZIP from GitHub Releases (or a fixed URL).
3. Extracts files and starts `HACPool-worker` with command-line arguments.
4. Writes worker logs in background.

## Template Description

`HACPool worker auto-bootstrap (download latest release, CLI args, auto-start)`

## Recommended Base Image

- `nvidia/cuda:12.2.0-runtime-ubuntu22.04`

## Entry Script (On-start, <=1024 chars)

```bash
#!/usr/bin/env bash
set -euo pipefail
curl -fsSL https://raw.githubusercontent.com/HacashCommunity/HACPool/refs/heads/main/scripts/start_vast_worker.sh | bash
```

## Required Variables

- `SERVER_ADDRESS` = `pool.hacash.community:3333`
- `REWARD_ADDRESS` = `YOUR_HAC_ADDRESS`

## Optional Variables

- `WORKER_NAME` (default: empty)
- `EFFORT` (optional; if set, must be `1..100`)
- `DEVICES` (optional)
- `WORKER_EXTRA_ARGS` (optional; extra `HACPool-worker` flags)
- `HACPOOL_WORKER_URL` (optional fixed release ZIP URL)

## Logs

- Bootstrap: `/workspace/HACPool-worker/bootstrap.log`
- Worker: `/workspace/HACPool-worker/worker.log`
