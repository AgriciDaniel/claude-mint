# GPU Management Directive

> Triggered by: `/mint gpu`

## Goal

Monitor GPU health, manage drivers, and optimize GPU performance for the user's workload.

## Inputs

- GPU model and driver info from `execution/audit/hardware.sh`
- User's intended use (gaming, ML, video editing, etc.)

## Tools/Scripts

- `execution/audit/hardware.sh` - Get GPU info
- NVIDIA tools: `nvidia-smi`, `nvidia-settings`
- `prime-select` - GPU switching (NVIDIA/AMD hybrid)
- `powerprofilesctl` - Power profile management

## Process

### 1. Detect GPU Configuration

```bash
source ~/.claude/execution/audit/hardware.sh
echo "Primary GPU: $AUDIT_GPU_MODEL"
echo "Driver: $AUDIT_GPU_DRIVER"
echo "CUDA: $AUDIT_GPU_CUDA"
echo "Secondary: $AUDIT_GPU_SECONDARY"
echo "PRIME Mode: $AUDIT_GPU_PRIME_MODE"
```

### 2. Display GPU Status

```
╔═══════════════════════════════════════════════════════════════╗
║                      GPU STATUS                                ║
╠═══════════════════════════════════════════════════════════════╣
║ GPU:          [Model]                                          ║
║ Architecture: [Turing/Ampere/etc.]                             ║
║ VRAM:         [XX GB]                                          ║
║ Driver:       [Version] ([open/proprietary])                   ║
║ CUDA:         [Version]                                        ║
║ PRIME Mode:   [on-demand/nvidia/intel]                         ║
╠═══════════════════════════════════════════════════════════════╣
║ Temperature:  [XX°C]                                           ║
║ Power:        [XXW / XXW]                                      ║
║ Utilization:  [XX%]                                            ║
║ Memory Used:  [XX / XX GB]                                     ║
╚═══════════════════════════════════════════════════════════════╝
```

### 3. NVIDIA GPU Commands

**Full status:**
```bash
nvidia-smi
```

**Temperature monitoring:**
```bash
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader
```

**Power usage:**
```bash
nvidia-smi --query-gpu=power.draw,power.limit --format=csv,noheader
```

**Memory usage:**
```bash
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader
```

**Continuous monitoring:**
```bash
watch -n 1 nvidia-smi
```

### 4. Driver Management

**Check current driver:**
```bash
nvidia-smi --query-gpu=driver_version --format=csv,noheader
```

**Check available drivers:**
```bash
ubuntu-drivers list
```

**Use mintdrivers (recommended for Mint):**
```bash
mintdrivers
# GUI tool that shows recommended and available drivers
```

**Install recommended driver:**
```bash
sudo ubuntu-drivers autoinstall
```

**Check kernel module type:**
```bash
modinfo nvidia | grep "^filename\|^version"
```

### 5. GPU Switching (PRIME)

Linux Mint uses `prime-select` for hybrid GPU switching.

**Check current mode:**
```bash
prime-select query
```

**Switch GPU mode:**
```bash
# Use NVIDIA for everything (max performance, more power)
sudo prime-select nvidia

# On-demand mode (default — use iGPU, offload to NVIDIA when needed)
sudo prime-select on-demand

# Use integrated GPU only (max battery life)
sudo prime-select intel

# Reboot required after switching!
sudo reboot
```

**Run specific app on NVIDIA (on-demand mode):**
```bash
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia application
# Or use the right-click menu in Nemo to "Run with NVIDIA GPU"
```

### 6. Screen Tearing Fix (NVIDIA)

```bash
# Via nvidia-settings GUI
nvidia-settings
# X Server Display Configuration > Advanced > Force Composition Pipeline: ON

# Via command line (persistent)
sudo nvidia-settings --assign CurrentMetaMode="nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
```

### 7. Power Profiles

```bash
# Check current profile
powerprofilesctl get

# Set profile
powerprofilesctl set balanced        # Default
powerprofilesctl set performance     # Max performance
powerprofilesctl set power-saver     # Power saving
```

### 8. Troubleshooting

**If GPU not detected:**
1. Check if module loaded: `lsmod | grep nvidia`
2. Check for errors: `dmesg | grep -i nvidia`
3. Reinstall driver: `sudo apt install --reinstall nvidia-driver-XXX`

**If driver mismatch after kernel update:**
1. Reboot to let DKMS rebuild
2. Or manually: `sudo dkms autoinstall`

**If GPU stuck at low performance:**
1. Check power profile: `powerprofilesctl get`
2. Set to performance: `powerprofilesctl set performance`
3. Check PRIME mode: `prime-select query`

## Outputs

- GPU status and health
- Driver information
- Recommendations based on current state

## Edge Cases

- **No NVIDIA GPU**: Check for AMD GPU with `glxinfo`
- **Driver not loaded**: Check dmesg, may need reinstall
- **After kernel update**: DKMS should rebuild automatically
- **Hybrid graphics**: Use prime-select for GPU switching

## AMD GPU Commands

If AMD discrete/integrated GPU:
```bash
# Check driver
lsmod | grep amdgpu

# GPU info
glxinfo | grep "OpenGL renderer"

# Temperature (if supported)
sensors | grep -A5 amdgpu
```

## Safety

- **NEVER** remove GPU driver without having recovery plan
- **ALWAYS** verify driver after kernel updates
- **CREATE** Timeshift snapshot before driver changes
- **CHECK** nouveau is blacklisted for NVIDIA

## Learnings

<!-- Updated by the agent when new insights are discovered -->
- Linux Mint uses prime-select for GPU switching (not system76-power)
- powerprofilesctl manages power profiles
- mintdrivers is the recommended GUI for driver management
- Screen tearing fix: ForceCompositionPipeline in nvidia-settings
- On-demand mode: apps run on iGPU by default, offload to NVIDIA with env vars
- External monitors on laptops often wired to dGPU — need prime-select nvidia/on-demand
- GTX 16xx series is Turing architecture
- Secure Boot may need MOK enrollment for NVIDIA drivers
