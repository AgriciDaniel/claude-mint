#!/bin/bash
# cinnamon.sh - Cinnamon desktop environment detection for Linux Mint
# Part of Mint System Assistant
# Exports AUDIT_* environment variables for Cinnamon-specific info

set -o pipefail

# ============================================
# CINNAMON DESKTOP DETECTION
# ============================================

detect_cinnamon_version() {
    # Cinnamon version
    AUDIT_CINNAMON_VERSION=$(cinnamon --version 2>/dev/null | awk '{print $2}')

    # Count installed Cinnamon packages
    AUDIT_CINNAMON_PACKAGES=$(dpkg -l 2>/dev/null | grep -c "^ii.*cinnamon" || echo "0")

    export AUDIT_CINNAMON_VERSION AUDIT_CINNAMON_PACKAGES
}

# ============================================
# SESSION DETECTION
# ============================================

detect_session() {
    # Session type (should be x11 for Cinnamon on Mint)
    AUDIT_SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"

    # Current desktop
    AUDIT_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-unknown}"

    # Check if Cinnamon is running
    if pgrep -x "cinnamon" > /dev/null; then
        AUDIT_CINNAMON_RUNNING="Yes"
    else
        AUDIT_CINNAMON_RUNNING="No"
    fi

    export AUDIT_SESSION_TYPE AUDIT_CURRENT_DESKTOP AUDIT_CINNAMON_RUNNING
}

# ============================================
# POWER MANAGEMENT
# ============================================

detect_power_profile() {
    AUDIT_POWER_PROFILE=""
    AUDIT_POWER_SERVICE=""

    if command -v powerprofilesctl &>/dev/null; then
        # Get current power profile
        AUDIT_POWER_PROFILE=$(powerprofilesctl get 2>/dev/null)

        # Check service status
        if systemctl is-active --quiet power-profiles-daemon 2>/dev/null; then
            AUDIT_POWER_SERVICE="Active"
        else
            AUDIT_POWER_SERVICE="Inactive"
        fi
    else
        AUDIT_POWER_PROFILE="N/A (power-profiles-daemon not installed)"
    fi

    export AUDIT_POWER_PROFILE AUDIT_POWER_SERVICE
}

# ============================================
# CINNAMON CONFIGURATION (gsettings/dconf)
# ============================================

detect_cinnamon_config() {
    AUDIT_CINNAMON_THEME=""
    AUDIT_CINNAMON_ICON_THEME=""
    AUDIT_CINNAMON_GTK_THEME=""
    AUDIT_CINNAMON_CURSOR_THEME=""
    AUDIT_CINNAMON_PANEL_LAYOUT=""
    AUDIT_CINNAMON_CUSTOM_KEYBINDINGS="0"

    # Desktop themes
    AUDIT_CINNAMON_THEME=$(gsettings get org.cinnamon.theme name 2>/dev/null | tr -d "'")
    AUDIT_CINNAMON_ICON_THEME=$(gsettings get org.cinnamon.desktop.interface icon-theme 2>/dev/null | tr -d "'")
    AUDIT_CINNAMON_GTK_THEME=$(gsettings get org.cinnamon.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    AUDIT_CINNAMON_CURSOR_THEME=$(gsettings get org.cinnamon.desktop.interface cursor-theme 2>/dev/null | tr -d "'")

    # Panel layout
    AUDIT_CINNAMON_PANEL_LAYOUT=$(gsettings get org.cinnamon panels-enabled 2>/dev/null | tr -d "[]'" | head -1)

    # Count custom keybindings
    local bindings=$(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null | tr -d "[]'@as " | tr ',' '\n' | grep -c .)
    AUDIT_CINNAMON_CUSTOM_KEYBINDINGS="${bindings:-0}"

    export AUDIT_CINNAMON_THEME AUDIT_CINNAMON_ICON_THEME AUDIT_CINNAMON_GTK_THEME
    export AUDIT_CINNAMON_CURSOR_THEME AUDIT_CINNAMON_PANEL_LAYOUT AUDIT_CINNAMON_CUSTOM_KEYBINDINGS
}

# ============================================
# CINNAMON APPLETS & EXTENSIONS
# ============================================

detect_cinnamon_applets() {
    AUDIT_CINNAMON_APPLETS=""
    AUDIT_CINNAMON_EXTENSIONS=""

    # Enabled applets
    local applets=$(gsettings get org.cinnamon enabled-applets 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | sed 's/.*://' | sort -u | tr '\n' ', ')
    AUDIT_CINNAMON_APPLETS="${applets%, }"
    [ -z "$AUDIT_CINNAMON_APPLETS" ] && AUDIT_CINNAMON_APPLETS="Default"

    # Enabled extensions
    local extensions=$(gsettings get org.cinnamon enabled-extensions 2>/dev/null | tr -d "[]'" | tr ',' '\n' | xargs)
    AUDIT_CINNAMON_EXTENSIONS="${extensions:-None}"

    export AUDIT_CINNAMON_APPLETS AUDIT_CINNAMON_EXTENSIONS
}

# ============================================
# LINUX MINT SPECIFIC
# ============================================

detect_mint_specific() {
    # Mint version info
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        AUDIT_MINT_VERSION="$VERSION"
        AUDIT_MINT_NAME="$PRETTY_NAME"
        AUDIT_MINT_CODENAME="$VERSION_CODENAME"
    fi

    # Mint edition (Cinnamon/MATE/Xfce)
    AUDIT_MINT_EDITION="Cinnamon"
    if [ -f /etc/linuxmint/info ]; then
        AUDIT_MINT_EDITION=$(grep "EDITION" /etc/linuxmint/info 2>/dev/null | cut -d= -f2 | xargs)
    fi

    # Ubuntu base codename
    AUDIT_MINT_UBUNTU_BASE=""
    if [ -f /etc/upstream-release/lsb-release ]; then
        AUDIT_MINT_UBUNTU_BASE=$(grep "DISTRIB_CODENAME" /etc/upstream-release/lsb-release 2>/dev/null | cut -d= -f2)
    fi

    # Firmware update tool
    if command -v fwupdmgr &>/dev/null; then
        AUDIT_MINT_FIRMWARE_TOOL="fwupdmgr"
    else
        AUDIT_MINT_FIRMWARE_TOOL="Not installed"
    fi

    # Mint Store
    if command -v mintinstall &>/dev/null; then
        AUDIT_MINT_STORE="Software Manager"
    else
        AUDIT_MINT_STORE="Not detected"
    fi

    export AUDIT_MINT_VERSION AUDIT_MINT_NAME AUDIT_MINT_CODENAME
    export AUDIT_MINT_EDITION AUDIT_MINT_UBUNTU_BASE
    export AUDIT_MINT_FIRMWARE_TOOL AUDIT_MINT_STORE
}

# ============================================
# MINT TOOLS DETECTION
# ============================================

detect_mint_tools() {
    AUDIT_MINT_TOOLS=""
    local tools=""

    # Core Mint tools
    command -v mintupdate-cli &>/dev/null && tools+="mintupdate, "
    command -v mintdrivers &>/dev/null && tools+="mintdrivers, "
    command -v mintbackup &>/dev/null && tools+="mintbackup, "
    command -v mintinstall &>/dev/null && tools+="mintinstall, "
    command -v mintsources &>/dev/null && tools+="mintsources, "
    command -v mintstick &>/dev/null && tools+="mintstick, "
    command -v mintreport &>/dev/null && tools+="mintreport, "
    command -v mintwelcome &>/dev/null && tools+="mintwelcome, "

    # Timeshift (first-class on Mint)
    command -v timeshift &>/dev/null && tools+="timeshift, "

    # Driver manager
    command -v ubuntu-drivers &>/dev/null && tools+="ubuntu-drivers, "

    # Mint upgrade tool
    command -v mintupgrade &>/dev/null && tools+="mintupgrade, "

    AUDIT_MINT_TOOLS="${tools%, }"

    export AUDIT_MINT_TOOLS
}

# ============================================
# FLATPAK DETECTION
# ============================================

detect_flatpak() {
    if command -v flatpak &>/dev/null; then
        AUDIT_FLATPAK_INSTALLED="Yes"
        AUDIT_FLATPAK_COUNT=$(flatpak list --app 2>/dev/null | wc -l)
        AUDIT_FLATPAK_REMOTES=$(flatpak remotes 2>/dev/null | wc -l)
    else
        AUDIT_FLATPAK_INSTALLED="No"
        AUDIT_FLATPAK_COUNT="0"
        AUDIT_FLATPAK_REMOTES="0"
    fi

    export AUDIT_FLATPAK_INSTALLED AUDIT_FLATPAK_COUNT AUDIT_FLATPAK_REMOTES
}

# ============================================
# X11 TOOLS
# ============================================

detect_x11_tools() {
    AUDIT_X11_TOOLS=""
    local tools=""

    # Clipboard
    command -v xclip &>/dev/null && tools+="xclip, "
    command -v xsel &>/dev/null && tools+="xsel, "

    # Input automation
    command -v xdotool &>/dev/null && tools+="xdotool, "
    command -v xte &>/dev/null && tools+="xte, "

    # Display
    command -v xrandr &>/dev/null && tools+="xrandr, "
    command -v arandr &>/dev/null && tools+="arandr, "

    # Screenshot
    command -v gnome-screenshot &>/dev/null && tools+="gnome-screenshot, "
    command -v flameshot &>/dev/null && tools+="flameshot, "

    # Screen annotation
    command -v gromit-mpx &>/dev/null && tools+="gromit-mpx, "

    AUDIT_X11_TOOLS="${tools%, }"

    export AUDIT_X11_TOOLS
}

# ============================================
# MAIN: RUN ALL DETECTIONS
# ============================================

main() {
    detect_cinnamon_version
    detect_session
    detect_power_profile
    detect_cinnamon_config
    detect_cinnamon_applets
    detect_mint_specific
    detect_mint_tools
    detect_flatpak
    detect_x11_tools
}

# Always run main to populate AUDIT_* variables
main

# Print summary if run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== Cinnamon Desktop Detection Summary ==="
    echo "Linux Mint:     $AUDIT_MINT_NAME"
    echo "Cinnamon:       $AUDIT_CINNAMON_VERSION"
    echo "Cinnamon Running: $AUDIT_CINNAMON_RUNNING"
    echo "Session Type:   $AUDIT_SESSION_TYPE"
    echo "Power Profile:  $AUDIT_POWER_PROFILE"
    echo "Theme:          $AUDIT_CINNAMON_THEME"
    echo "Icons:          $AUDIT_CINNAMON_ICON_THEME"
    echo "Custom Keys:    $AUDIT_CINNAMON_CUSTOM_KEYBINDINGS"
    echo "Mint Tools:     $AUDIT_MINT_TOOLS"
    echo "Flatpak Apps:   $AUDIT_FLATPAK_COUNT"
    echo "X11 Tools:      $AUDIT_X11_TOOLS"
fi
