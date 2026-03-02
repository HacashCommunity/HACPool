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
worker_id = ""
mining_mode = "cpu"
cpu_threads = 16
```

GPU/OpenCL example:

```toml
server_address = "pool.hacash.community:7001"
reward_address = "YOUR_HAC_WALLET_ADDRESS"
worker_id = ""
mining_mode = "gpu"
opencl_dir = "opencl"
opencl_platform_id = 0
# opencl_device_id = 0  # optional; if omitted, worker uses all GPUs on the selected platform
opencl_workgroups = 1024
opencl_local_size = 256
opencl_unit_size = 128
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
  - Example: `12zzCzDxEvNBuZRyGq2sqQKSGCYBJrAJHU`
  - Important: if this is invalid, worker startup fails.

- `worker_id`
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
  - Change only if your machine has multiple OpenCL platforms.

- `opencl_device_id`
  - What it does: selects GPU device index inside selected platform.
  - Typical value: `` (Empty)
  - If omitted: worker uses all GPUs found in the selected OpenCL platform.
  - Multi-GPU rigs:
    - Omit it to use all devices in one worker process.
    - Or set explicit IDs (`0`, `1`, `2`, ...) and run one worker per GPU.

- `opencl_workgroups`
  - What it does: number of workgroups launched per kernel call.
  - Typical values: `256`, `512`, `1024`, `2048`
  - Recommended start: `1024`

- `opencl_local_size`
  - What it does: local work size per workgroup.
  - Typical values: `64`, `128`, `256`
  - Recommended start: `256` (or `128` if unstable).

- `opencl_unit_size`
  - What it does: extra batching factor controlling total work per dispatch.
  - Typical values: `64`, `128`, `256`, `512`
  - Recommended start: `128`

### GPU tuning strategy (safe order)

1. Keep `opencl_platform_id` and `opencl_device_id` correct first.
2. Start from defaults: `workgroups=1024`, `local_size=256`, `unit_size=128`.
3. If unstable: reduce `local_size` to `128`, then reduce `workgroups`.
4. If stable and underperforming: increase `workgroups` gradually.
5. Change one field at a time and compare hashrate for a few minutes.

### Minimal templates

CPU (stable default):

```toml
server_address = "pool.hacash.community:7001"
reward_address = "YOUR_HAC_ADDRESS"
worker_id = "cpu-rig-01"
mining_mode = "cpu"
cpu_threads = 8
```

GPU (stable default):

```toml
server_address = "pool.hacash.community:7001"
reward_address = "YOUR_HAC_ADDRESS"
worker_id = "gpu-rig-01"
mining_mode = "gpu"
opencl_dir = "opencl"
opencl_platform_id = 0
# opencl_device_id = 0  # optional; omit to use all GPUs
opencl_workgroups = 1024
opencl_local_size = 256
opencl_unit_size = 128
```

### `worker_id` rules

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
- Verify your `reward_address` and `worker_id` are valid.

### Why are shares rejected?

- Wrong or stale job.
- High network latency.
- Invalid worker settings.
- Address mismatch with pool policy.
