# Performance Tuning Directive

> Triggered by: `/mint performance`

## Goal

Optimize system performance for the user's workload (development, gaming, content creation, etc.) while maintaining stability.

## Inputs

- Current system profile from audit scripts
- User's primary workload type
- Current performance issues (if any)

## Tools/Scripts

- `execution/audit/hardware.sh` - Get hardware info
- `powerprofilesctl` - Power profile management

## Process

### 1. Assess Current Performance

```bash
# CPU info and current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Check current power profile
powerprofilesctl get

# Memory pressure
cat /proc/meminfo | grep -E "MemAvailable|MemTotal|SwapTotal"

# I/O scheduler
cat /sys/block/nvme0n1/queue/scheduler
```

### 2. Display Performance Status

```
╔═══════════════════════════════════════════════════════════════╗
║                  PERFORMANCE STATUS                            ║
╠═══════════════════════════════════════════════════════════════╣
║ Power Profile:  [balanced/performance/power-saver]             ║
║ CPU Governor:   [performance/powersave/schedutil]             ║
║ I/O Scheduler:  [mq-deadline/bfq/kyber/none]                  ║
║ THP:            [always/madvise/never]                        ║
╠═══════════════════════════════════════════════════════════════╣
║ CPU:            [Model] @ [current freq]                       ║
║ Temperature:    [XX°C]                                         ║
║ RAM Used:       [XX / XX GB]                                   ║
║ Swap Used:      [XX / XX GB]                                   ║
╚═══════════════════════════════════════════════════════════════╝
```

### 3. Power Profile Optimization

**For maximum performance:**
```bash
powerprofilesctl set performance
```

**For balanced (recommended for daily use):**
```bash
powerprofilesctl set balanced
```

**For battery life (laptops):**
```bash
powerprofilesctl set power-saver
```

### 4. CPU Governor Settings

**Check available governors:**
```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
```

**Set performance governor (temporary):**
```bash
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

Note: powerprofilesctl handles this automatically based on profile.

### 5. Cinnamon Desktop Performance

**Disable desktop effects (big impact on lower-end GPUs):**
```bash
gsettings set org.cinnamon desktop-effects false
```

**Re-enable effects:**
```bash
gsettings set org.cinnamon desktop-effects true
```

**Reduce animations:**
System Settings > Effects > disable individual animations

### 6. I/O Scheduler Optimization

**For NVMe drives (recommended: none or mq-deadline):**
```bash
cat /sys/block/nvme0n1/queue/scheduler
echo "mq-deadline" | sudo tee /sys/block/nvme0n1/queue/scheduler
```

**Persistent setting:**
Create `/etc/udev/rules.d/60-scheduler.rules`:
```
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
```

### 7. Swappiness

**For systems with plenty of RAM (reduce swap usage):**
```bash
# Check current
cat /proc/sys/vm/swappiness

# Set (temporary)
sudo sysctl vm.swappiness=10

# Persistent
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.d/99-performance.conf
```

### 8. GPU-Specific Optimizations

**NVIDIA - Check PCIe link speed:**
```bash
nvidia-smi -q | grep -i "link"
```

**NVIDIA - Screen tearing fix:**
```bash
nvidia-settings --assign CurrentMetaMode="nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
```

**NVIDIA - Power mode:**
```bash
sudo nvidia-smi -pm 1  # Persistence mode
```

### 9. Real-Time Monitoring

```bash
# CPU/Memory/Disk
htop  # or btm

# GPU
watch -n 1 nvidia-smi

# I/O
iotop

# All temperatures
watch -n 2 sensors
```

## Workload-Specific Recommendations

### Development
- Power profile: Balanced
- Cinnamon effects: On (minimal impact with decent GPU)
- Plenty of RAM helps (compilation)

### Gaming
- Power profile: Performance
- GPU: `prime-select nvidia` (if hybrid)
- Cinnamon effects: Off
- Screen tearing: ForceCompositionPipeline

### Content Creation (Video Editing)
- Power profile: Performance
- GPU: CUDA/NVENC enabled
- Fast storage for media files

### Machine Learning
- Power profile: Performance
- GPU: Verify CUDA working
- Check GPU memory usage
- `prime-select nvidia` for full GPU access

## Outputs

- Current performance status
- Recommendations based on workload
- Commands to apply optimizations

## Edge Cases

- **Laptop**: Be careful with performance mode (heat/battery)
- **Thermal throttling**: Check temperatures first
- **Kernel update**: Settings may reset

## Safety

- **MONITOR** temperatures when setting performance mode
- **TEST** stability after changes
- **KEEP** balanced profile as default
- **DOCUMENT** any persistent changes made

## Learnings

<!-- Updated by the agent when new insights are discovered -->
- Linux Mint defaults are well-optimized for most users
- powerprofilesctl manages power profiles on Mint
- Disabling Cinnamon desktop effects is a quick performance win for older GPUs
- NVMe drives benefit from "none" scheduler
- Screen tearing on NVIDIA: ForceCompositionPipeline
- Swappiness=10 is good for 16GB+ RAM systems
