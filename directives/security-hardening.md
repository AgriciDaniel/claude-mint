# Security Hardening Directive

> Triggered by: `/mint security`

## Goal

Audit system security and achieve a score ≥90/100 while maintaining usability. Identify gaps and offer to fix them with user consent.

## Inputs

- Current security score from `execution/audit/security.sh`
- User consent required for each change

## Tools/Scripts

- `execution/audit/security.sh` - Calculate security score

## Process

### 1. Run Security Audit

```bash
source ~/.claude/execution/audit/security.sh
echo "Security Score: $AUDIT_SECURITY_SCORE/100"
```

### 2. Display Current Status

```
╔═══════════════════════════════════════════════════════════════╗
║                    SECURITY AUDIT                              ║
╠═══════════════════════════════════════════════════════════════╣
║ Score: XX/100 (Grade)                                          ║
╠═══════════════════════════════════════════════════════════════╣
║ [✓/✗] Firewall:      [status]                    [+10 pts]    ║
║ [✓/✗] Encryption:    [status]                    [+15 pts]    ║
║ [✓/✗] SSH:           [status]                    [+10 pts]    ║
║ [✓/✗] AppArmor:      [status]                    [+5 pts]     ║
║ [✓/✗] Auto-updates:  [status]                    [+5 pts]     ║
║ [✓/✗] Security tools: [status]                   [+X pts]     ║
║ [✓/✗] Kernel hardening: [status]                 [+5 pts]     ║
╚═══════════════════════════════════════════════════════════════╝
```

### 3. Identify Gaps and Recommendations

For each missing item, explain:
- What it does
- Why it's important
- How to enable it
- Any trade-offs

### 4. Offer Fixes (with user approval)

**Firewall not active (UFW is often INACTIVE by default):**
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo systemctl enable ufw

# Optional: Rate-limit SSH if needed
sudo ufw limit ssh

# GUI tool available:
sudo apt install gufw
```

**Auto-updates not configured:**
```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

**fail2ban not installed:**
```bash
sudo apt install fail2ban
sudo systemctl enable --now fail2ban
```

**Kernel hardening:**
Create `/etc/sysctl.d/99-security.conf`:
```bash
# Kernel pointer and dmesg restrictions
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.randomize_va_space = 2
kernel.perf_event_paranoid = 3
kernel.sysrq = 0
fs.suid_dumpable = 0
net.core.bpf_jit_harden = 2

# Network hardening
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1

# Filesystem protections
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
```
Apply: `sudo sysctl --system`

### 4b. CRITICAL: LUKS Header Backup

**If using disk encryption:**
```bash
lsblk -f | grep crypto_LUKS
sudo cryptsetup luksDump /dev/nvme0n1pX
sudo cryptsetup luksHeaderBackup /dev/nvme0n1pX --header-backup-file ~/luks-header-backup.img
```

### 4c. Secure Boot Considerations

**Linux Mint supports Secure Boot**, unlike Pop!_OS.

For NVIDIA systems, Secure Boot may be disabled because:
- NVIDIA proprietary drivers need to be signed
- MOK (Machine Owner Key) enrollment can solve this

**If Secure Boot is needed with NVIDIA:**
```bash
# When installing NVIDIA drivers via mintdrivers/ubuntu-drivers,
# Mint will prompt to set a MOK password
# On reboot, enroll the key in the blue MOKManager screen

# Or manually:
sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
# Reboot and complete enrollment
```

### 5. Re-run Audit

After changes, run audit again to verify improvements:
```bash
source ~/.claude/execution/audit/security.sh
echo "New Score: $AUDIT_SECURITY_SCORE/100"
```

### 6. Report Final Status

Show before/after comparison and remaining recommendations.

## Outputs

- Security score (before and after)
- List of changes made
- Remaining recommendations

## Edge Cases

- If user declines all changes: Respect decision, show manual instructions
- If command fails: Show error, suggest manual approach
- If score already ≥90: Congratulate, show what's working

## Safety

- **NEVER** disable disk encryption
- **NEVER** modify firewall without explicit consent
- **ALWAYS** backup configs before changes:
  ```bash
  sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d)
  ```
- **REQUIRE** user confirmation for each security change

## Learnings

<!-- Updated by the agent when new insights are discovered -->
- Base security score on Linux Mint with defaults: ~50-55
- **UFW is installed but often INACTIVE by default** — must enable manually
- AppArmor is loaded by default but may need sudo to check status
- Linux Mint supports Secure Boot (unlike Pop!_OS)
- NVIDIA + Secure Boot: use MOK enrollment
- **LUKS header backup is CRITICAL** — save to external drive
- Network hardening (accept_redirects, rp_filter) prevents many attacks
- Protected symlinks/hardlinks prevent symlink attacks
- mintupdate can be configured for automatic security updates
