# Backup & Recovery Directive

> Triggered by: `/mint backup`

## Goal

Manage system backups with Timeshift and provide recovery instructions. Ensure user has recent snapshots before risky operations.

## Inputs

- Current Timeshift configuration
- Available snapshots
- Disk space for snapshots

## Tools/Scripts

- `timeshift` - System snapshot tool (pre-installed on Linux Mint)
- `mintbackup` - User data backup tool
- GRUB2 boot menu for recovery

## Process

### 1. Check Timeshift Status

```bash
# Check if Timeshift is installed
command -v timeshift && echo "Timeshift installed" || echo "Not installed"

# List existing snapshots
sudo timeshift --list
```

### 2. Display Backup Status

```
╔═══════════════════════════════════════════════════════════════╗
║                    BACKUP STATUS                               ║
╠═══════════════════════════════════════════════════════════════╣
║ Tool: Timeshift                                                ║
║ Snapshots: X available                                         ║
║ Latest: YYYY-MM-DD_HH-MM-SS                                   ║
║ Scheduled: [Yes/No]                                            ║
╠═══════════════════════════════════════════════════════════════╣
║ Recent Snapshots:                                              ║
║ • [date] [type] [description]                                  ║
║ • [date] [type] [description]                                  ║
╚═══════════════════════════════════════════════════════════════╝
```

### 3. Timeshift Operations

**Create manual snapshot:**
```bash
sudo timeshift --create --comments "Before [operation]"
```

**List snapshots:**
```bash
sudo timeshift --list
```

**Delete old snapshot:**
```bash
sudo timeshift --delete --snapshot 'YYYY-MM-DD_HH-MM-SS'
```

**Restore from snapshot:**
```bash
sudo timeshift --restore --snapshot 'YYYY-MM-DD_HH-MM-SS'
```

### 4. Configure Scheduled Backups

**Open Timeshift GUI:**
```bash
sudo timeshift-gtk
```

Recommended schedule:
- **Daily**: Keep 5
- **Weekly**: Keep 3
- **Monthly**: Keep 2

### 5. Mintbackup (User Data)

Timeshift backs up the **system** but NOT `/home` by default. Use mintbackup for user data:

```bash
# Open mintbackup GUI
mintbackup

# Backs up: user files, software selection, PPA list
```

### 6. Recovery via GRUB

Linux Mint does **NOT** have a dedicated recovery partition like Pop!_OS. Instead:

**Access GRUB menu:**
- **UEFI**: Press `ESC` repeatedly during boot
- **Legacy BIOS**: Hold `SHIFT` during boot

**From GRUB menu:**
1. Select "Advanced options for Linux Mint"
2. Choose a previous kernel (if current kernel is broken)
3. Or select recovery mode

**Recovery mode options:**
- Resume normal boot
- Clean (attempt to repair broken packages)
- dpkg (repair broken packages)
- fsck (check filesystem)
- grub (update GRUB bootloader)
- network (enable networking)
- root (drop to root shell)

### 7. Emergency Recovery Steps

**If system won't boot:**

1. Boot from Linux Mint USB installer (or any Ubuntu-based live USB)
2. Open terminal
3. Mount the system:
   ```bash
   # Find your partitions
   lsblk -f

   # If encrypted (LUKS):
   sudo cryptsetup luksOpen /dev/nvme0n1pX cryptdata
   sudo mount /dev/mapper/cryptdata /mnt
   # Or if LVM:
   sudo lvchange -ay /dev/vgname/root
   sudo mount /dev/vgname/root /mnt

   # If NOT encrypted:
   sudo mount /dev/nvme0n1pX /mnt

   # Mount EFI partition (UEFI systems)
   sudo mount /dev/nvme0n1p1 /mnt/boot/efi
   ```

4. Chroot into system:
   ```bash
   for i in dev dev/pts proc sys run; do sudo mount -R /$i /mnt/$i; done
   sudo chroot /mnt
   ```

5. Fix the issue (examples):
   ```bash
   # Reinstall kernel and regenerate initramfs
   apt install --reinstall linux-image-generic linux-headers-generic
   update-initramfs -c -k all
   update-grub

   # Or reinstall NVIDIA driver
   apt install --reinstall nvidia-driver-XXX
   update-initramfs -u -k all
   update-grub
   ```

6. Exit and reboot:
   ```bash
   exit
   sudo reboot
   ```

**Restore Timeshift snapshot from live USB:**
```bash
# Install Timeshift in live environment if needed
sudo apt update && sudo apt install timeshift

# Restore (will detect existing snapshots)
sudo timeshift --restore
```

### 8. GRUB Repair

If GRUB is broken:

```bash
# From live USB, after mounting and chroot:
grub-install /dev/nvme0n1    # Or /dev/sda
update-grub

# Or use Boot Repair tool:
sudo add-apt-repository ppa:yannubuntu/boot-repair
sudo apt update
sudo apt install boot-repair
boot-repair
```

### 9. CRITICAL: LUKS Header Backup

**If your LUKS header is corrupted, your data is UNRECOVERABLE without a backup!**

```bash
# Find your LUKS partition first — adjust device path as needed
lsblk -f | grep crypto_LUKS

# View LUKS info and key slots
sudo cryptsetup luksDump /dev/nvme0n1pX

# BACKUP LUKS HEADER (save to external drive!)
sudo cryptsetup luksHeaderBackup /dev/nvme0n1pX --header-backup-file ~/luks-header-backup.img

# Add additional passphrase (optional, slot 1)
sudo cryptsetup luksAddKey /dev/nvme0n1pX

# Change existing passphrase
sudo cryptsetup luksChangeKey /dev/nvme0n1pX
```

**Store LUKS header backup SECURELY offline** — it can decrypt your drive!

## Outputs

- Current backup status
- List of snapshots
- Recovery instructions

## Edge Cases

- **Timeshift not installed**: `sudo apt install timeshift`
- **No space for snapshots**: Clear old snapshots or use external drive
- **Encrypted disk**: Timeshift handles LUKS, but recovery needs decryption first
- **No recovery partition**: Use Linux Mint USB installer as live recovery environment

## Safety

- **CREATE** snapshot before kernel/driver updates
- **CREATE** snapshot before major system changes
- **KEEP** at least 2-3 recent snapshots
- **TEST** recovery process occasionally
- **KEEP** a Linux Mint USB installer handy for emergency recovery

## Disk Space Considerations

```bash
# Check Timeshift snapshot size
sudo du -sh /run/timeshift/backup/

# Check available space
df -h /
```

Timeshift uses rsync and hard links, so incremental snapshots are space-efficient.

## Config File Backup

For Cinnamon and application configs (not covered by Timeshift):

```bash
# Backup Cinnamon config
dconf dump /org/cinnamon/ > ~/cinnamon-backup.dconf

# Backup Claude config
cp -r ~/.claude ~/.claude.backup.$(date +%Y%m%d)

# Restore Cinnamon config
dconf load /org/cinnamon/ < ~/cinnamon-backup.dconf
```

## Learnings

<!-- Updated by the agent when new insights are discovered -->
- Timeshift uses BTRFS snapshots if available, rsync otherwise
- Linux Mint does NOT have a recovery partition — use GRUB recovery or live USB
- LUKS encryption requires unlocking before recovery operations
- Timeshift doesn't backup /home by default (keeps it safe during restore)
- Use mintbackup for user data backup (complements Timeshift)
- Create snapshot before any `/mint security` hardening changes
- **LUKS header backup is CRITICAL** — without it, corrupted header = lost data
- GRUB recovery: hold SHIFT (BIOS) or ESC (UEFI) during boot
- Boot Repair tool can fix most GRUB issues
- Full chroot requires mounting dev, dev/pts, proc, sys, run
- After kernel repair, run `update-grub` to update boot config
