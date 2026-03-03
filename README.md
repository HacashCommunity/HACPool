# HACPool

Miner documentation for running `HACPool-worker`.

## 1) Quick Start

### Requirements

- A Hacash address to get rewards.
  - Check: https://wallet.hacash.org
- A pool worker binary:
  - Download last version from https://github.com/HacashCommunity/HACPool/releases

### Edit worker config

Edit `HACPool-worker.ini`.

Default behavior:
- The worker reads `HACPool-worker.ini` from the same directory as the executable.

Optional override:
- `--config <path-to-ini>`
- `<path-to-ini>` as the first positional argument

CPU example:

```toml
server_address = "pool.hacash.community:7001"
reward_address = "YOUR_HAC_ADDRESS"
worker_name = ""
mining_mode = "cpu"
cpu_threads = 16
```

GPU/OpenCL example:

```toml
server_address = "pool.hacash.community:7001"
reward_address = "YOUR_HAC_WALLET_ADDRESS"
worker_name = ""
mining_mode = "gpu"
opencl_dir = "opencl"
opencl_platform_id = 0 # set to 1 if miner fails to start
# opencl_device_id = 0  # optional; if omitted, worker uses all GPUs on the selected platform
gpu_effort_percent = 100
# opencl_workgroups = 2048 # optional; for advanced users
# opencl_local_size = 512 # optional; for advanced users
# opencl_unit_size = 1024 # optional; for advanced users
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

### Verify from logs

- You should see successful registration and heartbeat messages.
- You should see hashrate updates.
- You should see `submit_ack accepted=...` when shares are accepted.

### Optional: farm proxy

For many rigs:

`workers -> proxy -> HACPool-server`

Then set workers to:

- `server_address = "<your-proxy-ip>:7011"`

## 2) Worker Configuration

The worker reads a `.ini` file using TOML syntax.

### Configuration Reference

#### Core fields

- `server_address`
  - What it does: pool endpoint (`host:port`) used by the worker to connect.
  - Example: `pool.hacash.community:7001`
  - Tips: do not include `http://` or `https://`.

- `reward_address`
  - What it does: destination address that receives your mining rewards.
  - Example: `1HACPooLMf8q6EByvxrmn5tnnTS82p84ST`
  - Important: if this is invalid, worker startup fails.

- `worker_name`
  - What it does: label shown in pool UI/logs for this instance.
  - Example: `rig-01`, `farmA_gpu03`, or empty string `""`.
  - Tips: use unique IDs per rig for easier troubleshooting.

- `mining_mode`
  - Allowed values: `cpu`, `gpu`
  - What it does: selects CPU mining path or OpenCL GPU mining path.
  - Important: if set to `gpu` and OpenCL init fails, worker exits with error.

#### CPU mode

- `cpu_threads`
  - What it does: number of CPU mining lanes/threads used in parallel.
  - Typical values: `4` to `32` (depends on CPU cores/threads).
  - Recommended start:
    - Home PC: `4` to `8`
    - Dedicated CPU miner: `8` to `32`
  - Tuning:
    - Increase if hashrate is low and CPU has free capacity.
    - Decrease if system is unstable or too hot.

#### GPU/OpenCL mode

- `opencl_dir`
  - What it does: folder containing OpenCL kernel sources needed by miner.
  - Example: `"opencl"` (relative) or full absolute path.
  - Important: if this path is wrong or missing sources, worker exits with error.

- `opencl_platform_id`
  - What it does: selects OpenCL platform (driver stack/vendor).
  - Typical value: `0`
  - Tip: try `1` if miner fails to start.
  - Change only if your machine has multiple OpenCL platforms.

- `opencl_device_id`
  - What it does: selects GPU device index inside selected platform.
  - Typical value: `` (Empty)
  - If omitted: worker uses all GPUs found in the selected OpenCL platform.
  - Multi-GPU rigs:
    - Omit it to use all devices in one worker process.
    - Or set explicit IDs separated by comma (`0,1,2`) and run only selected GPUs.

- `gpu_effort_percent`
  - What it does: controls GPU load from `1` (lowest) to `100` (highest).
  - Typical values: `80` to `100`.
  - Recommended start: `100` for max performance, then reduce if heat/power is too high.

- `opencl_workgroups`
  - What it does: fixed workgroups. If set, this field is locked (not auto-tuned).
  - Recommended value: `1024`.
  - If omitted: value is auto-tuned.

- `opencl_local_size`
  - What it does: fixed local work size. If set, this field is locked (not auto-tuned).
  - Recommended value: `256`.
  - Allowed values: `512`, `256`, `128`, `64`.
  - If omitted: value is auto-tuned.

- `opencl_unit_size`
  - What it does: fixed batching unit. If set, this field is locked (not auto-tuned).
  - Recommended value: `256`
  - If omitted: value is auto-tuned.


### GPU tuning strategy (safe order)

1. Keep `opencl_platform_id` and `opencl_device_id` correct first.
2. The worker auto-tunes on startup (GPU mode):
   - Stage 1: finds stable `local_size`.
   - Stage 2: benchmarks `workgroups`.
   - Stage 3: benchmarks `unit_size`.
3. If you set any `opencl_*` field, that specific field is locked and skipped by auto-tune.
4. Auto-tune benchmarks currently run with `3` rounds per candidate.
5. The selected max stable params are treated as `100%` effort.
6. Final params are scaled by `gpu_effort_percent` and clamped to multiples of 16.

### Minimal templates

CPU (stable default):

```toml
server_address = "pool.hacash.community:7001"
reward_address = "YOUR_HAC_ADDRESS"
worker_name = ""
mining_mode = "cpu"
cpu_threads = 8
```

GPU (stable default, auto-tuned):

```toml
server_address = "pool.hacash.community:7001"
reward_address = "YOUR_HAC_ADDRESS"
worker_name = ""
mining_mode = "gpu"
opencl_dir = "opencl"
opencl_platform_id = 0 # set to 1 if miner fails to start
# opencl_device_id = 0  # optional; omit to use all GPUs
gpu_effort_percent = 100
```

### `worker_name` rules

- Max length: 20 characters.
- You can use uppercase/lowercase letters, numbers, and only these symbols: `@`, `.`, `_`, `-`.
- Empty string is allowed.

## 3) FAQ

### How do I choose config file path?

- Default: `HACPool-worker.ini` next to the executable.
- Optional: pass path with `--config <path>` or first positional argument.

### CPU worker is too slow. What should I do?

- Increase `cpu_threads` in CPU mode.
- If available, switch to GPU mode and configure OpenCL fields.

### My worker cannot connect. What should I check?

- Verify `server_address`.
- Verify firewall/NAT rules.
- Verify your `reward_address` and `worker_name` are valid.

### Why are shares rejected?

- Wrong or stale job.
- High network latency.
- Invalid worker settings.
- Address mismatch with pool policy.
