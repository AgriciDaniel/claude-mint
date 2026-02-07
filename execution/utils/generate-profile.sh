#!/bin/bash
# generate-profile.sh - Generate comprehensive CLAUDE.md system profile
# Part of Mint System Assistant
# Generates a profile matching the gold-standard format

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source audit scripts
source "$SCRIPT_DIR/../audit/hardware.sh"
source "$SCRIPT_DIR/../audit/security.sh"
source "$SCRIPT_DIR/../audit/cinnamon.sh"
source "$SCRIPT_DIR/../audit/software.sh"

# ============================================
# HEADER SECTION
# ============================================

generate_header() {
    local username=$(whoami)
    local hostname=$(hostname)
    local date=$(date +%Y-%m-%d)

    cat << EOF
# System Profile: ${username}'s Linux Mint Cinnamon Workstation

> Last Updated: ${date} (Security ${AUDIT_SECURITY_SCORE}/100)
> This file provides Claude with comprehensive knowledge about this system for optimal assistance.

---

EOF
}

# ============================================
# OPERATING SYSTEM SECTION
# ============================================

generate_os_section() {
    local kernel=$(uname -r)
    local arch=$(uname -m)
    local hostname=$(hostname)
    local username=$(whoami)
    local uid=$(id -u)
    local groups=$(groups | tr ' ' ', ')
    local shell=$(basename "$SHELL")

    cat << EOF
## Operating System

| Property | Value |
|----------|-------|
| **Distribution** | ${AUDIT_MINT_NAME:-Linux Mint} |
| **Edition** | ${AUDIT_MINT_EDITION:-Cinnamon} |
| **Based On** | Ubuntu ${AUDIT_MINT_UBUNTU_BASE:-noble} / Debian |
| **Desktop Environment** | Cinnamon ${AUDIT_CINNAMON_VERSION:-6.x} (GTK-based, X11) |
| **Session Type** | ${AUDIT_SESSION_TYPE:-x11} |
| **Kernel** | ${kernel} |
| **Architecture** | ${arch} |
| **Hostname** | ${hostname} |
| **Username** | ${username} |
| **User ID** | ${uid} |
| **Groups** | ${groups} |
| **Default Shell** | ${SHELL} |
| **Bootloader** | $(if [ -f /boot/efi/EFI/systemd/systemd-bootx64.efi ] 2>/dev/null; then echo "systemd-boot"; elif [ -f /boot/grub/grub.cfg ] 2>/dev/null; then echo "GRUB2"; else echo "Unknown"; fi) |

---

EOF
}

# ============================================
# HARDWARE SECTION
# ============================================

generate_hardware_section() {
    cat << EOF
## Hardware Specifications

### CPU
| Property | Value |
|----------|-------|
| **Model** | ${AUDIT_CPU_MODEL:-Unknown} |
EOF

    [ -n "$AUDIT_CPU_ARCH" ] && echo "| **Architecture** | ${AUDIT_CPU_ARCH} |"

    cat << EOF
| **Cores / Threads** | ${AUDIT_CPU_CORES:-?} / ${AUDIT_CPU_THREADS:-?} |
EOF

    [ -n "$AUDIT_CPU_MAX_FREQ" ] && echo "| **Max Frequency** | ${AUDIT_CPU_MAX_FREQ} |"
    [ -n "$AUDIT_CPU_L3_CACHE" ] && echo "| **L3 Cache** | ${AUDIT_CPU_L3_CACHE} |"
    [ -n "$AUDIT_CPU_FEATURES" ] && echo "| **Features** | ${AUDIT_CPU_FEATURES} |"

    cat << EOF

### Memory (RAM)
| Property | Value |
|----------|-------|
| **Total** | ${AUDIT_RAM_TOTAL:-Unknown} |
| **Type** | ${AUDIT_RAM_TYPE:-Unknown} |
EOF

    [ -n "$AUDIT_RAM_SPEED" ] && echo "| **Speed** | ${AUDIT_RAM_SPEED} |"
    local swap_info="${AUDIT_SWAP_TOTAL:-None}"
    [ -n "$AUDIT_ZRAM_SIZE" ] && swap_info+=" (+ ${AUDIT_ZRAM_SIZE}G zram)"
    echo "| **Swap** | ${swap_info} |"

    # GPU Section
    cat << EOF

### Primary GPU
| Property | Value |
|----------|-------|
| **Model** | ${AUDIT_GPU_MODEL:-Unknown} |
EOF

    [ -n "$AUDIT_GPU_ARCH" ] && echo "| **Architecture** | ${AUDIT_GPU_ARCH} |"
    [ -n "$AUDIT_GPU_VRAM" ] && echo "| **VRAM** | ${AUDIT_GPU_VRAM} |"
    [ -n "$AUDIT_GPU_DRIVER" ] && echo "| **Driver** | ${AUDIT_GPU_DRIVER}${AUDIT_GPU_DRIVER_TYPE:+ ($AUDIT_GPU_DRIVER_TYPE)} |"
    [ -n "$AUDIT_GPU_CUDA" ] && echo "| **CUDA Version** | ${AUDIT_GPU_CUDA} |"
    [ -n "$AUDIT_GPU_PRIME_MODE" ] && echo "| **PRIME Mode** | ${AUDIT_GPU_PRIME_MODE} |"

    # Secondary GPU if present
    if [ -n "$AUDIT_GPU_SECONDARY" ]; then
        cat << EOF

### Secondary GPU
| Property | Value |
|----------|-------|
| **Model** | ${AUDIT_GPU_SECONDARY} |
| **Driver** | ${AUDIT_GPU_SECONDARY_DRIVER:-unknown} (open source) |
EOF
    fi

    # Storage Section
    cat << EOF

### Storage
| Property | Value |
|----------|-------|
| **Model** | ${AUDIT_STORAGE_MODEL:-Unknown} |
| **Size** | ${AUDIT_STORAGE_SIZE:-Unknown} |
| **Type** | ${AUDIT_STORAGE_TYPE:-Unknown} |
| **Encryption** | ${AUDIT_STORAGE_ENCRYPTED:-Unknown} |
| **Used** | ${AUDIT_DISK_USED:-?} / ${AUDIT_DISK_TOTAL:-?} (${AUDIT_DISK_PERCENT:-?}) |
EOF

    # Display Section
    cat << EOF

### Display
| Property | Value |
|----------|-------|
| **Output** | ${AUDIT_DISPLAY_OUTPUT:-Unknown} |
EOF
    [ -n "$AUDIT_DISPLAY_MODEL" ] && echo "| **Model** | ${AUDIT_DISPLAY_MODEL} |"
    cat << EOF
| **Resolution** | ${AUDIT_DISPLAY_RESOLUTION:-Unknown} |
| **Refresh Rate** | ${AUDIT_DISPLAY_REFRESH:-Unknown} |
| **Connection** | ${AUDIT_DISPLAY_CONNECTION:-Unknown} |
EOF

    # Network Section
    cat << EOF

### Network
| Property | Value |
|----------|-------|
| **Interface** | ${AUDIT_NET_INTERFACE:-Unknown} |
| **Type** | ${AUDIT_NET_TYPE:-Unknown} |
| **Driver** | ${AUDIT_NET_DRIVER:-Unknown} |
EOF
    [ -n "$AUDIT_NET_SSID" ] && echo "| **SSID** | ${AUDIT_NET_SSID} |"
    [ -n "$AUDIT_NET_IP" ] && echo "| **IP** | ${AUDIT_NET_IP} |"

    # Audio Section
    cat << EOF

### Audio
| Property | Value |
|----------|-------|
| **Server** | ${AUDIT_AUDIO_SERVER:-Unknown}${AUDIT_AUDIO_VERSION:+ $AUDIT_AUDIO_VERSION} |
EOF
    [ -n "$AUDIT_AUDIO_OUTPUT" ] && echo "| **Default Output** | ${AUDIT_AUDIO_OUTPUT} |"
    [ -n "$AUDIT_AUDIO_INPUT" ] && echo "| **Default Input** | ${AUDIT_AUDIO_INPUT} |"

    cat << EOF

---

EOF
}

# ============================================
# CINNAMON DESKTOP SECTION
# ============================================

generate_cinnamon_section() {
    cat << EOF
## Cinnamon Desktop Environment

### Version & Components
| Property | Value |
|----------|-------|
| **Cinnamon Version** | ${AUDIT_CINNAMON_VERSION:-Unknown} |
| **Installed Packages** | ${AUDIT_CINNAMON_PACKAGES:-Unknown} |
| **Session Type** | ${AUDIT_SESSION_TYPE:-x11} |
| **Power Profile** | ${AUDIT_POWER_PROFILE:-Unknown} |
| **Mint Edition** | ${AUDIT_MINT_EDITION:-Cinnamon} |

### Theme Configuration
| Property | Value |
|----------|-------|
| **Desktop Theme** | ${AUDIT_CINNAMON_THEME:-Default} |
| **Icon Theme** | ${AUDIT_CINNAMON_ICON_THEME:-Default} |
| **GTK Theme** | ${AUDIT_CINNAMON_GTK_THEME:-Default} |
| **Cursor Theme** | ${AUDIT_CINNAMON_CURSOR_THEME:-Default} |

### Applets & Extensions
- **Applets**: ${AUDIT_CINNAMON_APPLETS:-Default}
- **Extensions**: ${AUDIT_CINNAMON_EXTENSIONS:-None}
- **Custom Keyboard Shortcuts**: ${AUDIT_CINNAMON_CUSTOM_KEYBINDINGS:-0}

### Cinnamon CLI Tools
\`\`\`bash
xrandr                           # Display configuration
gsettings list-schemas | grep cinnamon  # List Cinnamon settings
dconf dump /org/cinnamon/        # Dump all Cinnamon config
flameshot gui                    # Screenshot (if installed)
gnome-screenshot                 # Built-in screenshot
\`\`\`

### Configuration Methods
| Method | Usage |
|--------|-------|
| gsettings | \`gsettings get/set org.cinnamon.* key value\` |
| dconf | \`dconf read/write /org/cinnamon/path key\` |
| Cinnamon Settings | GUI: System Settings app |

### Mint System Tools
${AUDIT_MINT_TOOLS:-Not detected}

---

EOF
}

# ============================================
# DEVELOPMENT TOOLS SECTION
# ============================================

generate_dev_section() {
    cat << EOF
## Installed Development Tools

### Languages & Runtimes
| Tool | Version | Manager |
|------|---------|---------|
EOF

    [ -n "$AUDIT_PYTHON_VERSION" ] && echo "| Python | ${AUDIT_PYTHON_VERSION} | ${AUDIT_PYTHON_MANAGER} |"
    [ -n "$AUDIT_NODE_VERSION" ] && echo "| Node.js | ${AUDIT_NODE_VERSION} | ${AUDIT_NODE_MANAGER} |"
    [ -n "$AUDIT_NPM_VERSION" ] && echo "| npm | ${AUDIT_NPM_VERSION} | - |"
    [ -n "$AUDIT_RUST_VERSION" ] && echo "| Rust | ${AUDIT_RUST_VERSION} | rustup |"
    [ -n "$AUDIT_GO_VERSION" ] && echo "| Go | ${AUDIT_GO_VERSION} | system |"
    [ -n "$AUDIT_JAVA_VERSION" ] && echo "| Java | ${AUDIT_JAVA_VERSION} | system |"

    # Rust CLI Tools
    if [ -n "$AUDIT_RUST_CLI_TOOLS" ]; then
        cat << EOF

### Rust CLI Tools (cargo-installed)
${AUDIT_RUST_CLI_TOOLS}

**Location:** \`~/.cargo/bin/\` (user-local, in PATH)
EOF
    fi

    # Containers
    cat << EOF

### Containers & Services
| Service | Version | Status |
|---------|---------|--------|
EOF

    [ -n "$AUDIT_DOCKER_VERSION" ] && echo "| Docker | ${AUDIT_DOCKER_VERSION} | Running: ${AUDIT_DOCKER_RUNNING} |"
    [ -n "$AUDIT_PODMAN_VERSION" ] && echo "| Podman | ${AUDIT_PODMAN_VERSION} | Installed |"
    [ -n "$AUDIT_DISTROBOX_VERSION" ] && echo "| Distrobox | ${AUDIT_DISTROBOX_VERSION} | Installed |"

    # AI Tools
    if [ -n "$AUDIT_OLLAMA_VERSION" ] || [ "$AUDIT_CLAUDE_CODE" = "Installed" ]; then
        cat << EOF

### AI Tools
EOF
        [ -n "$AUDIT_OLLAMA_VERSION" ] && echo "- **Ollama**: ${AUDIT_OLLAMA_VERSION} (Running: ${AUDIT_OLLAMA_RUNNING})"
        [ -n "$AUDIT_OLLAMA_MODELS" ] && echo "  - Models: ${AUDIT_OLLAMA_MODELS}"
        [ "$AUDIT_CLAUDE_CODE" = "Installed" ] && echo "- **Claude Code**: Installed"
    fi

    # Version Control
    cat << EOF

### Version Control
EOF
    [ -n "$AUDIT_GIT_VERSION" ] && echo "- Git: ${AUDIT_GIT_VERSION}"
    [ -n "$AUDIT_GH_VERSION" ] && echo "- GitHub CLI: ${AUDIT_GH_VERSION}"

    cat << EOF

---

EOF
}

# ============================================
# APPLICATIONS SECTION
# ============================================

generate_apps_section() {
    cat << EOF
## Installed Applications

### Browsers
${AUDIT_BROWSERS:-None detected}

### Editors
${AUDIT_EDITORS:-None detected}

### Communication
${AUDIT_COMMUNICATION:-None detected}

### Creative & Media
${AUDIT_CREATIVE:-None detected}

### Productivity
${AUDIT_PRODUCTIVITY:-None detected}

### Utilities
${AUDIT_UTILITIES:-None detected}

### Mint System Tools
${AUDIT_MINT_APPS:-None detected}

### Package Sources
| Type | Count |
|------|-------|
| Flatpak | ${AUDIT_FLATPAK_COUNT:-0} apps |
| Flatpak Remotes | ${AUDIT_FLATPAK_REMOTES:-0} |

---

EOF
}

# ============================================
# SECURITY SECTION
# ============================================

generate_security_section() {
    cat << EOF
## Security Configuration

**Security Score: ${AUDIT_SECURITY_SCORE}/100** (${AUDIT_SECURITY_GRADE})

### Core Security
| Component | Status | Details |
|-----------|--------|---------|
| **Firewall** | ${AUDIT_FIREWALL_STATUS} | ${AUDIT_FIREWALL_RULES:-Default rules} |
| **Disk Encryption** | ${AUDIT_ENCRYPTION_STATUS} | ${AUDIT_ENCRYPTION_TYPE} |
| **SSH Server** | ${AUDIT_SSH_STATUS} | ${AUDIT_SSH_CONFIG} |
| **AppArmor** | ${AUDIT_MAC_STATUS} | ${AUDIT_MAC_PROFILES:-Active} |
| **Secure Boot** | ${AUDIT_SECUREBOOT_STATUS} | Linux Mint supports Secure Boot; may need MOK for NVIDIA |
| **Auto-updates** | ${AUDIT_AUTOUPDATES_STATUS} | ${AUDIT_AUTOUPDATES_CONFIG:-Not configured} |

### Security Tools Installed
${AUDIT_SECURITY_TOOLS}

### Kernel Hardening
${AUDIT_KERNEL_HARDENING}
EOF

    [ -n "$AUDIT_KERNEL_HARDENING_DETAILS" ] && echo "Settings: ${AUDIT_KERNEL_HARDENING_DETAILS}"

    cat << EOF

### Security Maintenance Commands
\`\`\`bash
# Check firewall status
sudo ufw status verbose

# Monthly rootkit scan (if rkhunter installed)
sudo rkhunter --check

# Quarterly security audit (if lynis installed)
sudo lynis audit system

# List Timeshift snapshots
sudo timeshift --list
\`\`\`

---

EOF
}

# ============================================
# QUICK REFERENCE SECTION
# ============================================

generate_quick_reference() {
    cat << EOF
## Quick Reference Commands

### System Information
\`\`\`bash
hostnamectl                       # System overview
uname -r                          # Kernel version
sensors                           # Temperature readings
nvidia-smi                        # GPU status (if NVIDIA)
powerprofilesctl get              # Current power profile
prime-select query                # GPU switching mode
\`\`\`

### Cinnamon Desktop
\`\`\`bash
xrandr                            # Display configuration
gsettings list-schemas | grep cinnamon  # Cinnamon schemas
dconf dump /org/cinnamon/         # Dump Cinnamon config
flameshot gui                     # Screenshot
\`\`\`

### Package Management
\`\`\`bash
mintupdate-cli list               # List available updates
mintupdate-cli upgrade            # Apply updates (safe levels)
sudo apt update                   # Update package list
sudo apt upgrade -y               # Install updates (apt)
sudo apt install <package>        # Install package
apt search <query>                # Search packages
sudo apt autoremove -y            # Remove orphaned packages
flatpak update                    # Update Flatpak apps
\`\`\`

### Security
\`\`\`bash
sudo ufw status                   # Firewall status
sudo ufw enable                   # Enable firewall
sudo ufw allow <port>             # Allow port
\`\`\`

### Services
\`\`\`bash
systemctl --failed                # Show failed services
systemctl status <service>        # Check service status
systemctl restart <service>       # Restart service
journalctl -u <service> -f        # Follow service logs
\`\`\`

### Logs
\`\`\`bash
journalctl -b                     # Current boot logs
journalctl -b -p err              # Boot errors only
dmesg | tail -50                  # Kernel messages
\`\`\`

---

EOF
}

# ============================================
# NOTES SECTION
# ============================================

generate_notes_section() {
    local n=0

    cat << EOF
## Notes for Claude

EOF

    n=$((n+1)); echo "${n}. **This is a Linux Mint Cinnamon workstation** - use Cinnamon-native tools and X11-compatible solutions"
    n=$((n+1)); echo "${n}. **Use xrandr** for display management (X11 session)"
    n=$((n+1)); echo "${n}. **Use apt or mintupdate-cli** for package management (Debian-based)"
    n=$((n+1)); echo "${n}. **No snap packages** - Linux Mint blocks snap by default; prefer Flatpak for sandboxed apps"
    n=$((n+1)); echo "${n}. **powerprofilesctl** manages power profiles (power-profiles-daemon)"
    n=$((n+1)); echo "${n}. **GRUB2** is the bootloader - configure via \`/etc/default/grub\` + \`sudo update-grub\`"
    n=$((n+1)); echo "${n}. **Timeshift** is the primary backup tool (pre-installed, first-class on Mint)"

    # GPU-specific notes
    if [ -n "$AUDIT_GPU_MODEL" ] && echo "$AUDIT_GPU_MODEL" | grep -qi nvidia; then
        n=$((n+1)); echo "${n}. **NVIDIA GPU present** - use nvidia-smi for monitoring; prime-select for GPU switching"
    fi

    # Mint tools
    if [ -n "$AUDIT_MINT_TOOLS" ]; then
        n=$((n+1)); echo "${n}. **Mint tools available** - ${AUDIT_MINT_TOOLS}"
    fi

    # Container access
    local has_docker=""
    groups 2>/dev/null | grep -q docker && has_docker="docker"
    groups 2>/dev/null | grep -q ollama && has_docker="$has_docker ollama"
    if [ -n "$has_docker" ]; then
        n=$((n+1)); echo "${n}. **User has group access** - ${has_docker} (no sudo needed)"
    fi

    # X11 tools
    if [ -n "$AUDIT_X11_TOOLS" ]; then
        n=$((n+1)); echo "${n}. **X11 tools available** - ${AUDIT_X11_TOOLS}"
    fi

    # Flatpak apps
    if [ "${AUDIT_FLATPAK_COUNT:-0}" -gt 0 ]; then
        n=$((n+1)); echo "${n}. **${AUDIT_FLATPAK_COUNT} Flatpak apps installed** - update with \`flatpak update\`"
    fi

    # Modern CLI tools
    if [ -n "$AUDIT_RUST_CLI_TOOLS" ]; then
        n=$((n+1)); echo "${n}. **Modern Rust CLI tools available** - prefer rg (grep), fd (find), bat (cat), eza (ls)"
    fi

    # Services status
    if [ "$AUDIT_FAILED_SERVICES" != "All OK" ]; then
        n=$((n+1)); echo "${n}. **Warning**: ${AUDIT_FAILED_SERVICES} - check with \`systemctl --failed\`"
    fi

    cat << EOF

---

*Generated by Mint System Assistant*
EOF
}

# ============================================
# MAIN: GENERATE COMPLETE PROFILE
# ============================================

main() {
    generate_header
    generate_os_section
    generate_hardware_section
    generate_cinnamon_section
    generate_dev_section
    generate_apps_section
    generate_security_section
    generate_quick_reference
    generate_notes_section
}

# Output profile (can be redirected to file)
main
