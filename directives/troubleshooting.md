# Troubleshooting Directive

> Triggered by: `/mint troubleshoot`

## Goal

Systematically diagnose and resolve common issues on Linux Mint Cinnamon systems.

## Inputs

- User's description of the problem
- Category of issue (display, audio, network, boot, app, etc.)

## Tools/Scripts

- System logs: `journalctl`, `dmesg`
- Service status: `systemctl`
- Hardware detection: audit scripts

## Process

### 1. Identify Issue Category

Ask user to describe the problem, then categorize:
- **Display**: Black screen, wrong resolution, tearing
- **Audio**: No sound, wrong device, crackling
- **Network**: No connection, slow speed, drops
- **Boot**: Won't boot, slow boot, errors
- **Application**: Won't launch, crashes, slow
- **GPU**: Driver issues, performance, CUDA
- **Desktop**: Cinnamon issues, crashes, freezes

### 2. Gather Relevant Logs

**For all issues:**
```bash
# Recent errors
journalctl -b -p err --no-pager | tail -50

# Kernel messages
dmesg | tail -50
```

**Display issues:**
```bash
journalctl -b | grep -iE "gpu|nvidia|drm|display"
dmesg | grep -iE "nvidia|drm"
nvidia-smi  # if NVIDIA
```

**Audio issues:**
```bash
pactl info
pw-top  # PipeWire processes
journalctl -b | grep -iE "audio|pipewire|pulse|alsa"
aplay -l  # List audio devices
```

**Network issues:**
```bash
nmcli device status
ip addr
journalctl -b | grep -iE "network|wifi|wlan|eth"
ping -c 3 8.8.8.8
```

**Boot issues:**
```bash
systemd-analyze blame  # Slow services
systemctl --failed  # Failed services
journalctl -b -p warning --no-pager | head -100
```

### 3. Common Issues & Solutions

---

#### Display: Black Screen After Login (NVIDIA)

**Check:**
```bash
journalctl -b | grep -i nvidia
nvidia-smi
```

**Recovery from TTY (Ctrl+Alt+F3):**
```bash
# Full NVIDIA driver recovery
sudo apt update
sudo apt install --reinstall nvidia-driver-XXX
sudo update-initramfs -u -k all
sudo reboot
```

**If nouveau is conflicting:**
```bash
# Blacklist nouveau driver permanently
echo -e "blacklist nouveau\noptions nouveau modeset=0" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
sudo update-initramfs -u
sudo reboot
```

**Switch to integrated GPU (laptops with prime-select):**
```bash
sudo prime-select intel    # or: on-demand
sudo reboot
```

**Verify GPU usage after fix:**
```bash
glxinfo | grep vendor
nvidia-smi  # Shows active processes using GPU
```

---

#### Display: Wrong Resolution / No External Monitor

**Check:**
```bash
xrandr
```

**Solutions:**
1. Use System Settings > Display
2. Or: `xrandr --output HDMI-1 --mode 1920x1080 --rate 60`
3. Check cable connection
4. For NVIDIA laptops: External monitors often wired to dGPU — need `prime-select nvidia` or `prime-select on-demand`

---

#### Display: Screen Tearing (NVIDIA)

**Fix via nvidia-settings:**
```bash
nvidia-settings
# Go to: X Server Display Configuration > Advanced > Force Composition Pipeline: ON
```

**Persistent fix (xorg.conf):**
```bash
sudo nvidia-settings --assign CurrentMetaMode="nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
```

**Alternative — enable Cinnamon VSync:**
System Settings > General > Desktop Effects > check "Use Vsync"

---

#### Display: Cinnamon in Software Rendering Mode

**Symptoms:** Slow desktop, "Running in software rendering mode" warning

**Check:**
```bash
glxinfo | grep "OpenGL renderer"
# If shows "llvmpipe" = software rendering
```

**Fix:**
```bash
# Reinstall NVIDIA driver
sudo apt install --reinstall nvidia-driver-XXX
sudo update-initramfs -u -k all
sudo reboot
```

---

#### Audio: No Sound

**Check:**
```bash
pactl info
pactl list sinks short
```

**Solutions:**
1. Check correct output device: `pactl set-default-sink SINK_NAME`
2. Restart audio services:
   ```bash
   systemctl --user restart wireplumber pipewire pipewire-pulse
   # Or for PulseAudio:
   pulseaudio --kill && pulseaudio --start
   ```
3. Check if muted in system tray sound applet

---

#### Audio: Crackling/Popping Sound

**Fix (increase PipeWire buffer):**
```bash
mkdir -p ~/.config/pipewire/pipewire-pulse.conf.d/
echo "pulse.min.quantum = 1024/48000" > ~/.config/pipewire/pipewire-pulse.conf.d/buffer.conf
systemctl --user restart pipewire pipewire-pulse
```

---

#### Network: No WiFi Connection

**Check:**
```bash
nmcli device status
nmcli radio wifi
lspci | grep -i wireless  # Identify chipset
```

**Solutions:**
1. Enable WiFi: `nmcli radio wifi on`
2. Restart NetworkManager: `sudo systemctl restart NetworkManager`
3. Check if 5GHz preferred

**Broadcom WiFi fix (common on some laptops):**
```bash
sudo apt install broadcom-sta-dkms
sudo reboot
```

---

#### Network: Connection Drops

**Check:**
```bash
journalctl -b | grep -iE "NetworkManager|wlan"
```

**Solutions:**

**1. Disable WiFi power management (most effective):**
```bash
echo -e "[connection]\nwifi.powersave = 2" | sudo tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
sudo systemctl restart NetworkManager
```

**2. Update firmware:**
```bash
sudo fwupdmgr update
```

---

#### Boot: System Won't Boot

**Access GRUB menu:**
- **UEFI**: Press `ESC` repeatedly during boot
- **Legacy BIOS**: Hold `SHIFT` during boot

**From GRUB:**
1. Select "Advanced options for Linux Mint"
2. Choose previous kernel or recovery mode

**Full boot repair from live USB:**
```bash
# 1. Mount system (adjust device paths — verify with lsblk -f)
sudo mount /dev/nvme0n1pX /mnt
sudo mount /dev/nvme0n1p1 /mnt/boot/efi  # UEFI systems

# 2. If LUKS encrypted:
sudo cryptsetup luksOpen /dev/nvme0n1pX cryptdata
sudo mount /dev/mapper/cryptdata /mnt

# 3. Chroot
for i in dev dev/pts proc sys run; do sudo mount -R /$i /mnt/$i; done
sudo chroot /mnt

# 4. Repair
apt install --reinstall linux-image-generic linux-headers-generic
update-initramfs -c -k all
update-grub

# 5. Exit and reboot
exit
sudo reboot
```

---

#### Boot: Slow Boot

**Check:**
```bash
systemd-analyze blame
systemd-analyze critical-chain
```

**Solutions:**
1. Identify slow services
2. Disable unnecessary services: `sudo systemctl disable SERVICE`
3. Check for failed network waits

---

#### Cinnamon: Panel/Dock Missing

**Solutions:**
```bash
# Restart Cinnamon (keeps windows open)
cinnamon --replace &

# Or via dbus
dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon org.Cinnamon.Restart
```

---

#### Cinnamon: Desktop Freezes

**If mouse moves but can't click:**
```bash
# Switch to TTY: Ctrl+Alt+F3
# Log in, then:
cinnamon --replace &
# Switch back: Ctrl+Alt+F7 (or F1)
```

**If completely frozen:**
- Magic SysRq (if enabled): `Alt+SysRq+REISUB` to safely reboot
- Hard power off as last resort

---

#### Cinnamon: Reset All Configuration

**If Cinnamon behaves erratically:**
```bash
# Reset all Cinnamon settings
dconf reset -f /org/cinnamon/

# Log out and log back in
```

---

#### GPU: CUDA Not Working

**Check:**
```bash
nvidia-smi
nvcc --version  # If CUDA toolkit installed
```

**Solutions:**
1. Verify driver: `nvidia-smi`
2. Install CUDA toolkit if needed
3. Check library paths: `ldconfig -p | grep cuda`
4. Set environment variables:
   ```bash
   export CUDA_HOME=/usr/local/cuda
   export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64"
   export PATH="/usr/local/cuda/bin:$PATH"
   ```

---

#### GPU: External Monitor Not Working (Laptop)

**External monitors on laptops are often wired directly to the NVIDIA GPU.**

**Solution:** Switch to nvidia or on-demand mode:
```bash
sudo prime-select on-demand    # Or: nvidia
sudo reboot
```

---

#### Bluetooth: Devices Not Pairing

**Reset Bluetooth:**
```bash
sudo apt install --reinstall bluez
rm -rf ~/.local/share/bluetooth
sudo systemctl restart bluetooth
```

---

### 4. Diagnostic Commands Summary

| Issue | Quick Check |
|-------|-------------|
| Display | `nvidia-smi`, `xrandr` |
| Audio | `pactl info`, `pw-top` |
| Network | `nmcli device status` |
| Services | `systemctl --failed` |
| Boot | `journalctl -b -p err` |
| Disk | `df -h`, `lsblk` |
| Memory | `free -h` |
| CPU | `sensors`, `top` |

### 5. When to Escalate

If issue persists after basic troubleshooting:
1. Search Linux Mint forums (forums.linuxmint.com)
2. Check Ubuntu/Mint bug trackers
3. Use WebSearch for specific error messages

## Outputs

- Diagnosis of the problem
- Step-by-step solution
- Verification that fix worked

## Edge Cases

- **Multiple issues**: Address one at a time
- **Hardware failure**: May need physical inspection
- **Kernel regression**: Try older kernel from GRUB boot menu

## Safety

- **CREATE** Timeshift snapshot before major fixes
- **BACKUP** configs before modifying
- **DOCUMENT** changes made for rollback
- **TEST** after each change

## Learnings

<!-- Updated by the agent when new insights are discovered -->
- Most display issues on Linux Mint are NVIDIA driver related
- PipeWire/PulseAudio: restart it first for audio issues
- 5GHz WiFi is more reliable than 2.4GHz on many adapters
- Cinnamon is X11-native; no Wayland compatibility issues
- Screen tearing: enable ForceCompositionPipeline in nvidia-settings
- Cinnamon can be restarted without losing windows: `cinnamon --replace &`
- Software rendering mode usually means NVIDIA driver not loaded
- Linux Mint uses GRUB2 — hold SHIFT/ESC at boot for menu
- Broadcom WiFi often needs broadcom-sta-dkms package
- Audio crackling fixed by increasing PipeWire buffer
- External monitors on laptops often wired to dGPU — need prime-select
- After driver reinstall, always run `update-initramfs -u -k all`
