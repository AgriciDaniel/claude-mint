#!/bin/bash
# security.sh - Security auditing for Linux Mint
# Part of Mint System Assistant
# Calculates security score (Base: 50, Max: 100)

set -o pipefail

# Initialize score
AUDIT_SECURITY_SCORE=50

# ============================================
# FIREWALL CHECK
# ============================================

check_firewall() {
    AUDIT_FIREWALL_STATUS=""
    AUDIT_FIREWALL_RULES=""

    if command -v ufw &>/dev/null; then
        local status=$(sudo ufw status 2>/dev/null | head -1)
        if echo "$status" | grep -qi "active"; then
            AUDIT_FIREWALL_STATUS="UFW (active)"
            ((AUDIT_SECURITY_SCORE += 10))

            # Count rules
            local rule_count=$(sudo ufw status 2>/dev/null | grep -cE "^[0-9]+|ALLOW|DENY" || echo "0")
            AUDIT_FIREWALL_RULES="$rule_count rules"
        else
            AUDIT_FIREWALL_STATUS="UFW (inactive)"
        fi
    else
        # Check iptables as fallback
        if sudo iptables -L -n 2>/dev/null | grep -qE "ACCEPT|DROP|REJECT"; then
            AUDIT_FIREWALL_STATUS="iptables (configured)"
            ((AUDIT_SECURITY_SCORE += 5))
        else
            AUDIT_FIREWALL_STATUS="None detected"
        fi
    fi

    export AUDIT_FIREWALL_STATUS AUDIT_FIREWALL_RULES
}

# ============================================
# DISK ENCRYPTION CHECK
# ============================================

check_encryption() {
    AUDIT_ENCRYPTION_STATUS=""
    AUDIT_ENCRYPTION_TYPE=""

    # Check for LUKS
    if lsblk -o FSTYPE 2>/dev/null | grep -q "crypto_LUKS"; then
        AUDIT_ENCRYPTION_STATUS="Enabled"
        AUDIT_ENCRYPTION_TYPE="LUKS"
        ((AUDIT_SECURITY_SCORE += 15))

        # Check if root is on encrypted volume
        if findmnt -n -o SOURCE / 2>/dev/null | grep -q "mapper"; then
            AUDIT_ENCRYPTION_TYPE="LUKS (full disk)"
        fi
    # Check for encrypted LVM
    elif grep -q "cryptdata\|cryptswap" /etc/crypttab 2>/dev/null; then
        AUDIT_ENCRYPTION_STATUS="Enabled"
        AUDIT_ENCRYPTION_TYPE="LUKS via crypttab"
        ((AUDIT_SECURITY_SCORE += 15))
    else
        AUDIT_ENCRYPTION_STATUS="Not detected"
        AUDIT_ENCRYPTION_TYPE="None"
    fi

    export AUDIT_ENCRYPTION_STATUS AUDIT_ENCRYPTION_TYPE
}

# ============================================
# SSH CHECK
# ============================================

check_ssh() {
    AUDIT_SSH_STATUS=""
    AUDIT_SSH_CONFIG=""

    # Check if SSH server is running
    if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
        AUDIT_SSH_STATUS="Running"

        # Check SSH configuration
        local sshd_config="/etc/ssh/sshd_config"
        local password_auth=$(grep -E "^PasswordAuthentication" "$sshd_config" 2>/dev/null | awk '{print $2}')
        local root_login=$(grep -E "^PermitRootLogin" "$sshd_config" 2>/dev/null | awk '{print $2}')

        # Password authentication
        if [ "$password_auth" = "no" ]; then
            AUDIT_SSH_CONFIG="key-only auth"
            ((AUDIT_SECURITY_SCORE += 5))
        else
            AUDIT_SSH_CONFIG="password auth enabled"
            ((AUDIT_SECURITY_SCORE -= 10))
        fi

        # Root login
        if [ "$root_login" = "no" ]; then
            AUDIT_SSH_CONFIG+=", no root login"
        elif [ "$root_login" = "yes" ]; then
            AUDIT_SSH_CONFIG+=", root login ENABLED"
            ((AUDIT_SECURITY_SCORE -= 5))
        fi
    else
        AUDIT_SSH_STATUS="Disabled"
        AUDIT_SSH_CONFIG="Not running (good)"
        ((AUDIT_SECURITY_SCORE += 10))
    fi

    export AUDIT_SSH_STATUS AUDIT_SSH_CONFIG
}

# ============================================
# MANDATORY ACCESS CONTROL CHECK
# ============================================

check_mac() {
    AUDIT_MAC_STATUS=""
    AUDIT_MAC_PROFILES=""

    # Check AppArmor (default on Ubuntu/Mint)
    if [ -d /sys/kernel/security/apparmor ]; then
        AUDIT_MAC_STATUS="AppArmor (loaded)"
        ((AUDIT_SECURITY_SCORE += 5))

        # Count enforced profiles
        if command -v aa-status &>/dev/null; then
            local enforced=$(sudo aa-status 2>/dev/null | grep "profiles are in enforce mode" | awk '{print $1}')
            AUDIT_MAC_PROFILES="$enforced profiles enforced"
        fi
    # Check SELinux (fallback)
    elif command -v sestatus &>/dev/null && sestatus 2>/dev/null | grep -q "enabled"; then
        AUDIT_MAC_STATUS="SELinux (enabled)"
        ((AUDIT_SECURITY_SCORE += 5))
        local mode=$(sestatus 2>/dev/null | grep "Current mode" | awk '{print $3}')
        AUDIT_MAC_PROFILES="Mode: $mode"
    else
        AUDIT_MAC_STATUS="Not detected"
    fi

    export AUDIT_MAC_STATUS AUDIT_MAC_PROFILES
}

# ============================================
# AUTO-UPDATES CHECK
# ============================================

check_autoupdates() {
    AUDIT_AUTOUPDATES_STATUS=""
    AUDIT_AUTOUPDATES_CONFIG=""

    # Check mintupdate automatic updates (Mint-specific)
    local mint_auto="/etc/mintupdate.conf"
    if [ -f "$mint_auto" ]; then
        if grep -q "autorefresh-enabled=True" "$mint_auto" 2>/dev/null; then
            AUDIT_AUTOUPDATES_STATUS="mintupdate (auto-refresh)"
            AUDIT_AUTOUPDATES_CONFIG="mintupdate auto-refresh active"
            ((AUDIT_SECURITY_SCORE += 3))
        fi
    fi

    # Check unattended-upgrades (Debian/Ubuntu/Mint)
    if dpkg -l 2>/dev/null | grep -q "ii.*unattended-upgrades"; then
        if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
            local enabled=$(grep "APT::Periodic::Unattended-Upgrade" /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null | grep -o '"[0-9]*"' | tr -d '"')
            if [ "$enabled" = "1" ]; then
                AUDIT_AUTOUPDATES_STATUS="Enabled"
                AUDIT_AUTOUPDATES_CONFIG="unattended-upgrades active"
                ((AUDIT_SECURITY_SCORE += 5))
            else
                [ -z "$AUDIT_AUTOUPDATES_STATUS" ] && AUDIT_AUTOUPDATES_STATUS="Installed but disabled"
                AUDIT_AUTOUPDATES_CONFIG="${AUDIT_AUTOUPDATES_CONFIG:+$AUDIT_AUTOUPDATES_CONFIG, }unattended-upgrades not configured"
            fi
        else
            [ -z "$AUDIT_AUTOUPDATES_STATUS" ] && AUDIT_AUTOUPDATES_STATUS="Installed but not configured"
        fi
    else
        [ -z "$AUDIT_AUTOUPDATES_STATUS" ] && AUDIT_AUTOUPDATES_STATUS="Not installed"
    fi

    export AUDIT_AUTOUPDATES_STATUS AUDIT_AUTOUPDATES_CONFIG
}

# ============================================
# SECURITY TOOLS CHECK
# ============================================

check_security_tools() {
    AUDIT_SECURITY_TOOLS=""
    local tools_found=""

    # fail2ban
    if command -v fail2ban-client &>/dev/null; then
        tools_found+="fail2ban, "
        ((AUDIT_SECURITY_SCORE += 5))
    fi

    # rkhunter
    if command -v rkhunter &>/dev/null; then
        tools_found+="rkhunter, "
        ((AUDIT_SECURITY_SCORE += 5))
    fi

    # chkrootkit
    if command -v chkrootkit &>/dev/null; then
        tools_found+="chkrootkit, "
        ((AUDIT_SECURITY_SCORE += 3))
    fi

    # lynis
    if command -v lynis &>/dev/null; then
        tools_found+="lynis, "
        ((AUDIT_SECURITY_SCORE += 3))
    fi

    # ClamAV
    if command -v clamscan &>/dev/null; then
        tools_found+="clamav, "
        ((AUDIT_SECURITY_SCORE += 2))
    fi

    # Remove trailing comma
    AUDIT_SECURITY_TOOLS="${tools_found%, }"
    [ -z "$AUDIT_SECURITY_TOOLS" ] && AUDIT_SECURITY_TOOLS="None installed"

    export AUDIT_SECURITY_TOOLS
}

# ============================================
# KERNEL HARDENING CHECK
# ============================================

check_kernel_hardening() {
    AUDIT_KERNEL_HARDENING=""
    local hardened_count=0
    local checks_total=7
    local details=""

    # Check kptr_restrict (should be 2 for strictest)
    local kptr=$(sysctl -n kernel.kptr_restrict 2>/dev/null)
    if [ "$kptr" = "2" ]; then
        ((hardened_count++))
        details+="kptr_restrict=2, "
    fi

    # Check dmesg_restrict (should be 1)
    local dmesg=$(sysctl -n kernel.dmesg_restrict 2>/dev/null)
    if [ "$dmesg" = "1" ]; then
        ((hardened_count++))
        details+="dmesg_restrict, "
    fi

    # Check sysrq (should be 0 or restricted value)
    local sysrq=$(sysctl -n kernel.sysrq 2>/dev/null)
    if [ "$sysrq" = "0" ]; then
        ((hardened_count++))
        details+="sysrq=0, "
    fi

    # Check ptrace_scope (should be 1+)
    local ptrace=$(sysctl -n kernel.yama.ptrace_scope 2>/dev/null)
    if [ "${ptrace:-0}" -ge 1 ]; then
        ((hardened_count++))
        details+="ptrace_scope=$ptrace, "
    fi

    # Check perf_event_paranoid (should be 3 for strictest)
    local perf=$(sysctl -n kernel.perf_event_paranoid 2>/dev/null)
    if [ "${perf:-0}" -ge 2 ]; then
        ((hardened_count++))
        details+="perf_paranoid=$perf, "
    fi

    # Check BPF JIT hardening (should be 2)
    local bpf=$(sysctl -n net.core.bpf_jit_harden 2>/dev/null)
    if [ "$bpf" = "2" ]; then
        ((hardened_count++))
        details+="bpf_jit_harden, "
    fi

    # Check SUID core dumps (should be 0)
    local suid=$(sysctl -n fs.suid_dumpable 2>/dev/null)
    if [ "$suid" = "0" ]; then
        ((hardened_count++))
        details+="suid_dumpable=0, "
    fi

    # Calculate score contribution
    if [ "$hardened_count" -ge 5 ]; then
        ((AUDIT_SECURITY_SCORE += 5))
        AUDIT_KERNEL_HARDENING="Hardened ($hardened_count/$checks_total)"
    elif [ "$hardened_count" -ge 3 ]; then
        ((AUDIT_SECURITY_SCORE += 2))
        AUDIT_KERNEL_HARDENING="Partial ($hardened_count/$checks_total)"
    else
        AUDIT_KERNEL_HARDENING="Minimal ($hardened_count/$checks_total)"
    fi

    AUDIT_KERNEL_HARDENING_DETAILS="${details%, }"

    export AUDIT_KERNEL_HARDENING AUDIT_KERNEL_HARDENING_DETAILS
}

# ============================================
# SECURE BOOT CHECK
# ============================================

check_secureboot() {
    AUDIT_SECUREBOOT_STATUS=""

    if [ -d /sys/firmware/efi ]; then
        if mokutil --sb-state 2>/dev/null | grep -qi "enabled"; then
            AUDIT_SECUREBOOT_STATUS="Enabled"
            ((AUDIT_SECURITY_SCORE += 3))
        else
            AUDIT_SECUREBOOT_STATUS="Disabled"
            # Note: May be needed for NVIDIA drivers; MOK enrollment can help
        fi
    else
        AUDIT_SECUREBOOT_STATUS="N/A (Legacy BIOS)"
    fi

    export AUDIT_SECUREBOOT_STATUS
}

# ============================================
# PENDING UPDATES CHECK
# ============================================

check_pending_updates() {
    AUDIT_PENDING_UPDATES=""

    # Check apt updates
    if command -v apt &>/dev/null; then
        # Only if apt cache is fresh enough (less than 1 hour old)
        local cache_time=$(stat -c %Y /var/cache/apt/pkgcache.bin 2>/dev/null || echo "0")
        local current_time=$(date +%s)
        local age=$((current_time - cache_time))

        if [ "$age" -lt 3600 ]; then
            local count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")
            AUDIT_PENDING_UPDATES="$count packages"
        else
            AUDIT_PENDING_UPDATES="Unknown (apt cache stale)"
        fi
    fi

    export AUDIT_PENDING_UPDATES
}

# ============================================
# CALCULATE FINAL SCORE
# ============================================

calculate_final_score() {
    # Cap score at 0-100
    [ "$AUDIT_SECURITY_SCORE" -gt 100 ] && AUDIT_SECURITY_SCORE=100
    [ "$AUDIT_SECURITY_SCORE" -lt 0 ] && AUDIT_SECURITY_SCORE=0

    # Generate score label
    if [ "$AUDIT_SECURITY_SCORE" -ge 90 ]; then
        AUDIT_SECURITY_GRADE="Excellent"
    elif [ "$AUDIT_SECURITY_SCORE" -ge 80 ]; then
        AUDIT_SECURITY_GRADE="Good"
    elif [ "$AUDIT_SECURITY_SCORE" -ge 60 ]; then
        AUDIT_SECURITY_GRADE="Adequate"
    elif [ "$AUDIT_SECURITY_SCORE" -ge 40 ]; then
        AUDIT_SECURITY_GRADE="Needs improvement"
    else
        AUDIT_SECURITY_GRADE="Critical"
    fi

    export AUDIT_SECURITY_SCORE AUDIT_SECURITY_GRADE
}

# ============================================
# MAIN: RUN ALL CHECKS
# ============================================

main() {
    check_firewall
    check_encryption
    check_ssh
    check_mac
    check_autoupdates
    check_security_tools
    check_kernel_hardening
    check_secureboot
    check_pending_updates
    calculate_final_score
}

# Always run main to populate AUDIT_* variables
main

# Print summary if run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== Security Audit Summary ==="
    echo "Score: $AUDIT_SECURITY_SCORE/100 ($AUDIT_SECURITY_GRADE)"
    echo ""
    echo "Firewall:       $AUDIT_FIREWALL_STATUS"
    echo "Encryption:     $AUDIT_ENCRYPTION_STATUS ($AUDIT_ENCRYPTION_TYPE)"
    echo "SSH:            $AUDIT_SSH_STATUS - $AUDIT_SSH_CONFIG"
    echo "AppArmor:       $AUDIT_MAC_STATUS"
    echo "Auto-updates:   $AUDIT_AUTOUPDATES_STATUS"
    echo "Security tools: $AUDIT_SECURITY_TOOLS"
    echo "Kernel:         $AUDIT_KERNEL_HARDENING"
    echo "Secure Boot:    $AUDIT_SECUREBOOT_STATUS"
fi
