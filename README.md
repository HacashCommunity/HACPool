# HACPool

Miner documentation for running `HACPool-worker`.

## 1) Quick Start

### Requirements

- A Hacash address to get rewards.
  - Check: https://wallet.hacash.org
- A CUDA-capable NVIDIA GPU.
- A pool worker binary:
  - Download last version from https://github.com/HacashCommunity/HACPool/releases

### Edit worker config

Edit `HACPool-worker.ini`.

Default behavior:
- The worker reads `HACPool-worker.ini` from the same directory as the executable.

Optional override:
- `--config <path-to-ini>`
- `<path-to-ini>` as the first positional argument
- Any CLI mining args (`-o/--url`, `-u/--user`, `--devices`, `--effort`) override `.ini` values.

Example:

```toml
server_address = "pool.hacash.community:3333"
reward_address = "YOUR_HAC_WALLET_ADDRESS"
worker_name = ""
# devices = 0  # optional; if omitted, worker uses all GPUs
effort = 100
```

### Start worker

Default config path (`HACPool-worker.ini` next to executable):

```powershell
HACPool-worker.exe
```

Custom config path:

```powershell
HACPool-worker.exe --config "D:\\miners\\HACPool-worker.ini"
```

Command Line:

```powershell
HACPool-worker.exe -o stratum+tcp://pool.hacash.community:3333 -u YOUR_HAC_WALLET_ADDRESS

HACPool-worker.exe -o stratum+tcp://pool.hacash.community:3333 -u YOUR_HAC_WALLET_ADDRESS.WORKER_NAME

HACPool-worker.exe -o stratum+tcp://pool.hacash.community:3333 -u YOUR_HAC_WALLET_ADDRESS.WORKER_NAME --effort 100
```

### Verify from logs

- You should see starting on stratum and hashrate messages.
- You should see hashrate updates.
- You should see `Shares: X/Y` when shares are accepted.

## 2) Worker Configuration

The worker reads a `.ini` file using TOML syntax.

### Configuration Reference

#### Core fields

- `server_address`
  - What it does: pool endpoint (`host:port`) used by the worker to connect.
  - Example: `pool.hacash.community:3333`
  - Tips: do not include `http://` or `https://`.
  - Command-line argument: `-o` / `--url` (example: `-o stratum+tcp://pool.hacash.community:3333`)

- `reward_address`
  - What it does: destination address that receives your mining rewards.
  - Example: `1HACPooLMf8q6EByvxrmn5tnnTS82p84ST`
  - Important: if this is invalid, worker startup fails.
  - Command-line argument: `-u` / `--user` (example: `-u YOUR_HAC_ADDRESS`)

- `worker_name`
  - What it does: label shown in pool UI/logs for this instance.
  - Example: `rig-01`, `farmA_gpu03`, or empty string `""`.
  - Tips: use unique IDs per rig for easier troubleshooting.
  - Command-line argument: part of `-u` / `--user` as suffix `ADDRESS.WORKER_NAME` (example: `-u YOUR_HAC_ADDRESS.rig-01`)

- `devices`
  - What it does: selects GPU device index inside selected platform.
  - Typical value: `` (Empty)
  - If omitted: worker uses all GPUs found
  - Multi-GPU rigs:
    - Omit it to use all devices in one worker process.
    - Or set explicit IDs separated by comma (`0,1,2`) and run only selected GPUs.
  - Command-line argument: `--devices` (example: `--devices 0,1,2`)

- `effort`
  - What it does: controls GPU load from `1` (lowest) to `100` (highest).
  - Typical values: `80` to `100`.
  - Recommended start: `100` for max performance, then reduce if heat/power is too high.
  - Command-line argument: `--effort` (example: `--effort 100`)


### GPU tuning strategy

1. Keep `devices` correct first.
2. The worker auto-tunes on startup.
3. The selected max stable throughput is treated as `100%` effort.
4. Final throughput is scaled by `effort`.

### Minimal template

```toml
server_address = "pool.hacash.community:3333"
reward_address = "YOUR_HAC_ADDRESS"
```

### `worker_name` rules

- Max length: 20 characters.
- You can use uppercase/lowercase letters, numbers, and only these symbols: `@`, `.`, `_`, `-`.
- Empty string is allowed.

## 3) FAQ

### How do I choose config file path?

- Default: `HACPool-worker.ini` next to the executable.
- Optional: pass path with `--config <path>` or first positional argument.

### My worker cannot connect. What should I check?

- Verify `server_address`.
- Verify firewall/NAT rules.
- Verify your `reward_address` and `worker_name` are valid.

### Why are shares rejected?

- Wrong or stale job.
- High network latency.
- Invalid worker settings.
- Address mismatch with pool policy.
- Wrong worker file. Download again from official site.

## 4) Deployment Guides

- HiveOS: [README-hiveos.md](./README-hiveos.md)
- Vast.ai: [README-vast.md](./README-vast.md)
