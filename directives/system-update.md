# System Update Directive

> Triggered by: `/mint update`

## Goal

Safely update system packages with minimal disruption. Categorize updates, warn about critical changes (kernel, GPU drivers), and verify system health after updates.

## Inputs

- Current package state
- GPU driver version (critical - don't break GPU)
- User confirmation before applying

## Tools/Scripts

- `execution/audit/hardware.sh` - Get current GPU driver version
- `mintupdate-cli` - Linux Mint update manager CLI
- GRUB2 (`/etc/default/grub` + `update-grub`) - Boot configuration

## Process

### 1. Check for Updates

```bash
# Refresh package lists
sudo apt update

# List available updates via mintupdate
mintupdate-cli list 2>/dev/null

# Also check apt directly
apt list --upgradable 2>/dev/null | tail -n +2
```

### 2. Categorize Updates

Group updates into categories:
- **Security**: Updates with "security" in origin
- **Kernel**: linux-image-*, linux-headers-*
- **GPU Driver**: nvidia-*, libnvidia-*
- **Cinnamon**: cinnamon-*, nemo-*
- **Regular**: Everything else

```bash
# Count by category
apt list --upgradable 2>/dev/null | grep -i security | wc -l
apt list --upgradable 2>/dev/null | grep -E "linux-image|linux-headers" | wc -l
apt list --upgradable 2>/dev/null | grep -i nvidia | wc -l
apt list --upgradable 2>/dev/null | grep -E "cinnamon|nemo" | wc -l
```

### 3. Display Summary

```
╔═══════════════════════════════════════════════════════════════╗
║                    SYSTEM UPDATES                              ║
╠═══════════════════════════════════════════════════════════════╣
║ Security updates:    X packages                                ║
║ Kernel updates:      X packages  ⚠️  May require reboot       ║
║ GPU driver updates:  X packages  ⚠️  Verify after update      ║
║ Cinnamon updates:    X packages                                ║
║ Regular updates:     X packages                                ║
╠═══════════════════════════════════════════════════════════════╣
║ Total: XX packages                                             ║
╚═══════════════════════════════════════════════════════════════╝
```

### 4. Warn About Critical Updates

**If kernel update:**
- Warn about potential reboot requirement
- Mention GRUB boot menu to select older kernel if issues

**If GPU driver update:**
- Record current driver version: `nvidia-smi --query-gpu=driver_version --format=csv,noheader`
- Warn about potential display issues
- Mention recovery steps

### 5. Get User Confirmation

Ask: "Proceed with updates? (y/n)"

### 6. Apply Updates

```bash
# Option A: Use mintupdate-cli (respects safety levels)
sudo mintupdate-cli upgrade

# Option B: Use apt directly (all updates)
sudo apt upgrade -y

# Check if reboot required
if [ -f /var/run/reboot-required ]; then
    echo "⚠️  Reboot required"
fi
```

### 7. Update Flatpak (if installed)

```bash
flatpak update -y
```

### 8. Verify GPU Driver

```bash
# Check NVIDIA driver
nvidia-smi
```

### 9. Report Results

```
╔═══════════════════════════════════════════════════════════════╗
║                    UPDATE COMPLETE                             ║
╠═══════════════════════════════════════════════════════════════╣
║ ✓ XX packages updated                                          ║
║ ✓ GPU driver verified: [version]                               ║
║ ✓/⚠️ Reboot: [required/not required]                          ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## Linux Mint Release Upgrades

**IMPORTANT: Use `mintupgrade`, NOT `do-release-upgrade`!**

Linux Mint has its own upgrade tool that handles Cinnamon and Mint-specific packages properly.

```bash
# Check if mintupgrade is installed
sudo apt install mintupgrade

# Run the upgrade tool (interactive)
sudo mintupgrade
```

**Note:** `mintupgrade` is interactive and guides you through the process. It will:
1. Check system compatibility
2. Remove incompatible packages
3. Upgrade to the new release
4. Handle Cinnamon and Mint tool updates

---

## GRUB Boot Configuration

**Linux Mint uses GRUB2 as the bootloader.**

```bash
# View current GRUB config
cat /etc/default/grub

# Edit GRUB configuration
sudo nano /etc/default/grub

# ALWAYS apply changes after editing
sudo update-grub

# Common kernel boot options
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia-drm.modeset=1"
```

**Access GRUB menu at boot:**
- **UEFI**: Press `ESC` repeatedly during boot
- **Legacy BIOS**: Hold `SHIFT` during boot

---

## Mintupdate Safety Levels

| Level | Risk | Description |
|-------|------|-------------|
| 1 | Minimal | Tested, certified safe |
| 2 | Low | Safe updates |
| 3 | Medium | Generally safe, may affect system |
| 4 | High | May affect system stability |
| 5 | Critical | Kernel, NVIDIA drivers, etc. |

**Blacklist specific packages:**
```bash
# Via mintupdate GUI: Edit > Preferences > Blacklist
# Or via CLI config in /etc/mintupdate.conf
```

## Outputs

- List of updated packages
- Reboot requirement status
- GPU driver verification

## Edge Cases

- **If no updates available**: Report "System is up to date"
- **If apt update fails**: Check network, try `sudo apt update --fix-missing`
- **If GPU driver breaks after update (from TTY — Ctrl+Alt+F3):**
  ```bash
  sudo apt update
  sudo apt install --reinstall nvidia-driver-XXX
  sudo update-initramfs -u -k all
  sudo reboot
  ```
- **If kernel update breaks boot**:
  1. Hold SHIFT (BIOS) or ESC (UEFI) during boot for GRUB menu
  2. Select "Advanced options for Linux Mint"
  3. Select previous kernel version
- **If package system is broken:**
  ```bash
  sudo dpkg --configure -a
  sudo apt install -f
  sudo apt full-upgrade
  ```

## Safety

- **NEVER** force updates without user confirmation
- **ALWAYS** verify GPU driver after updates
- **ALWAYS** check reboot requirement
- **BACKUP** important work before kernel/driver updates
- **CREATE** Timeshift snapshot before major updates

## Learnings

<!-- Updated by the agent when new insights are discovered -->
- Linux Mint handles NVIDIA drivers well via mintdrivers
- Timeshift snapshot before updates is a safety net
- Flatpak apps update separately from apt
- Cinnamon updates may require logout/login to take effect
- **Use mintupgrade for release upgrades, NOT do-release-upgrade**
- **Use GRUB2 for boot configuration, NOT kernelstub**
- mintupdate-cli respects safety levels (1-5)
- After driver reinstall, always run `update-initramfs -u -k all`
- Access GRUB menu: hold SHIFT (BIOS) or ESC (UEFI) during boot
