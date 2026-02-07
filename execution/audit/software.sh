#!/bin/bash
# software.sh - Software and development environment detection for Linux Mint
# Part of Mint System Assistant
# Exports AUDIT_* environment variables for software/dev tools

set -o pipefail

# ============================================
# DEVELOPMENT LANGUAGES & RUNTIMES
# ============================================

detect_python() {
    AUDIT_PYTHON_VERSION=""
    AUDIT_PYTHON_MANAGER=""

    # Check pyenv first
    if [ -d "$HOME/.pyenv" ] && command -v pyenv &>/dev/null; then
        AUDIT_PYTHON_VERSION=$(pyenv version-name 2>/dev/null)
        AUDIT_PYTHON_MANAGER="pyenv"
        AUDIT_PYTHON_PATH="$HOME/.pyenv/shims/python"
    # Check system python
    elif command -v python3 &>/dev/null; then
        AUDIT_PYTHON_VERSION=$(python3 --version 2>/dev/null | awk '{print $2}')
        AUDIT_PYTHON_MANAGER="system"
        AUDIT_PYTHON_PATH=$(which python3)
    fi

    export AUDIT_PYTHON_VERSION AUDIT_PYTHON_MANAGER AUDIT_PYTHON_PATH
}

detect_nodejs() {
    AUDIT_NODE_VERSION=""
    AUDIT_NODE_MANAGER=""
    AUDIT_NPM_VERSION=""

    # Check nvm first
    if [ -d "$HOME/.nvm" ]; then
        # Source nvm if not loaded
        [ -s "$HOME/.nvm/nvm.sh" ] && source "$HOME/.nvm/nvm.sh" 2>/dev/null
        if command -v node &>/dev/null; then
            AUDIT_NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//')
            AUDIT_NODE_MANAGER="nvm"
            AUDIT_NPM_VERSION=$(npm --version 2>/dev/null)
        fi
    # Check system node
    elif command -v node &>/dev/null; then
        AUDIT_NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//')
        AUDIT_NODE_MANAGER="system"
        AUDIT_NPM_VERSION=$(npm --version 2>/dev/null)
    fi

    export AUDIT_NODE_VERSION AUDIT_NODE_MANAGER AUDIT_NPM_VERSION
}

detect_rust() {
    AUDIT_RUST_VERSION=""
    AUDIT_CARGO_VERSION=""

    if [ -d "$HOME/.cargo" ] && command -v rustc &>/dev/null; then
        AUDIT_RUST_VERSION=$(rustc --version 2>/dev/null | awk '{print $2}')
        AUDIT_CARGO_VERSION=$(cargo --version 2>/dev/null | awk '{print $2}')
        AUDIT_RUST_PATH="$HOME/.cargo/bin"
    fi

    export AUDIT_RUST_VERSION AUDIT_CARGO_VERSION AUDIT_RUST_PATH
}

detect_java() {
    AUDIT_JAVA_VERSION=""

    if command -v java &>/dev/null; then
        AUDIT_JAVA_VERSION=$(java -version 2>&1 | head -1 | awk -F'"' '{print $2}')
    fi

    export AUDIT_JAVA_VERSION
}

detect_go() {
    AUDIT_GO_VERSION=""

    if command -v go &>/dev/null; then
        AUDIT_GO_VERSION=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
    fi

    export AUDIT_GO_VERSION
}

# ============================================
# RUST CLI TOOLS
# ============================================

detect_rust_cli_tools() {
    AUDIT_RUST_CLI_TOOLS=""
    local tools=""

    # Modern CLI tool replacements
    command -v rg &>/dev/null && tools+="ripgrep (rg), "
    command -v fd &>/dev/null && tools+="fd-find (fd), "
    command -v bat &>/dev/null && tools+="bat, "
    command -v eza &>/dev/null && tools+="eza, "
    command -v btm &>/dev/null && tools+="bottom (btm), "
    command -v dust &>/dev/null && tools+="du-dust (dust), "
    command -v delta &>/dev/null && tools+="delta, "
    command -v zoxide &>/dev/null && tools+="zoxide, "
    command -v starship &>/dev/null && tools+="starship, "
    command -v hyperfine &>/dev/null && tools+="hyperfine, "
    command -v tokei &>/dev/null && tools+="tokei, "

    AUDIT_RUST_CLI_TOOLS="${tools%, }"

    export AUDIT_RUST_CLI_TOOLS
}

# ============================================
# CONTAINERS
# ============================================

detect_containers() {
    AUDIT_DOCKER_VERSION=""
    AUDIT_DOCKER_RUNNING=""
    AUDIT_PODMAN_VERSION=""
    AUDIT_DISTROBOX_VERSION=""

    # Docker
    if command -v docker &>/dev/null; then
        AUDIT_DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')
        if systemctl is-active --quiet docker 2>/dev/null; then
            AUDIT_DOCKER_RUNNING="Yes"
        else
            AUDIT_DOCKER_RUNNING="No"
        fi
    fi

    # Podman
    if command -v podman &>/dev/null; then
        AUDIT_PODMAN_VERSION=$(podman --version 2>/dev/null | awk '{print $3}')
    fi

    # Distrobox
    if command -v distrobox &>/dev/null; then
        AUDIT_DISTROBOX_VERSION=$(distrobox --version 2>/dev/null | awk '{print $2}')
    fi

    export AUDIT_DOCKER_VERSION AUDIT_DOCKER_RUNNING AUDIT_PODMAN_VERSION AUDIT_DISTROBOX_VERSION
}

# ============================================
# AI/ML TOOLS
# ============================================

detect_ai_tools() {
    AUDIT_OLLAMA_VERSION=""
    AUDIT_OLLAMA_MODELS=""
    AUDIT_OLLAMA_RUNNING=""

    # Ollama
    if command -v ollama &>/dev/null; then
        AUDIT_OLLAMA_VERSION=$(ollama --version 2>/dev/null | awk '{print $NF}')

        if systemctl is-active --quiet ollama 2>/dev/null; then
            AUDIT_OLLAMA_RUNNING="Yes"
            # List models
            AUDIT_OLLAMA_MODELS=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | tr '\n' ', ' | sed 's/, $//')
        else
            AUDIT_OLLAMA_RUNNING="No"
        fi
    fi

    # Claude Code
    if command -v claude &>/dev/null; then
        AUDIT_CLAUDE_CODE="Installed"
    else
        AUDIT_CLAUDE_CODE="Not installed"
    fi

    export AUDIT_OLLAMA_VERSION AUDIT_OLLAMA_MODELS AUDIT_OLLAMA_RUNNING AUDIT_CLAUDE_CODE
}

# ============================================
# CODE EDITORS
# ============================================

detect_editors() {
    AUDIT_EDITORS=""
    local editors=""

    # VS Code
    if command -v code &>/dev/null; then
        local vscode_ver=$(code --version 2>/dev/null | head -1)
        editors+="VS Code $vscode_ver, "
    fi

    # Mint default text editor (xed)
    command -v xed &>/dev/null && editors+="xed, "

    # Other editors
    command -v nvim &>/dev/null && editors+="Neovim, "
    command -v vim &>/dev/null && editors+="Vim, "
    command -v nano &>/dev/null && editors+="nano, "
    command -v helix &>/dev/null && editors+="Helix, "
    command -v emacs &>/dev/null && editors+="Emacs, "
    command -v gedit &>/dev/null && editors+="gedit, "
    command -v sublime_text &>/dev/null && editors+="Sublime Text, "

    AUDIT_EDITORS="${editors%, }"

    export AUDIT_EDITORS
}

# ============================================
# BROWSERS
# ============================================

detect_browsers() {
    AUDIT_BROWSERS=""
    local browsers=""

    command -v brave-browser &>/dev/null && browsers+="Brave, "
    command -v firefox &>/dev/null && browsers+="Firefox, "
    command -v google-chrome &>/dev/null && browsers+="Chrome, "
    command -v chromium &>/dev/null && browsers+="Chromium, "
    command -v zen-browser &>/dev/null && browsers+="Zen, "
    command -v vivaldi &>/dev/null && browsers+="Vivaldi, "
    command -v epiphany &>/dev/null && browsers+="GNOME Web, "

    AUDIT_BROWSERS="${browsers%, }"

    export AUDIT_BROWSERS
}

# ============================================
# COMMUNICATION APPS
# ============================================

detect_communication() {
    AUDIT_COMMUNICATION=""
    local apps=""

    # Check flatpak apps
    if command -v flatpak &>/dev/null; then
        flatpak list --app 2>/dev/null | grep -qi discord && apps+="Discord, "
        flatpak list --app 2>/dev/null | grep -qi slack && apps+="Slack, "
        flatpak list --app 2>/dev/null | grep -qi telegram && apps+="Telegram, "
        flatpak list --app 2>/dev/null | grep -qi signal && apps+="Signal, "
        flatpak list --app 2>/dev/null | grep -qi zoom && apps+="Zoom, "
        flatpak list --app 2>/dev/null | grep -qi teams && apps+="Teams, "
        flatpak list --app 2>/dev/null | grep -qi element && apps+="Element, "
    fi

    # Check native apps
    command -v thunderbird &>/dev/null && apps+="Thunderbird, "

    AUDIT_COMMUNICATION="${apps%, }"
    [ -z "$AUDIT_COMMUNICATION" ] && AUDIT_COMMUNICATION="None detected"

    export AUDIT_COMMUNICATION
}

# ============================================
# CREATIVE APPS
# ============================================

detect_creative() {
    AUDIT_CREATIVE=""
    local apps=""

    # Image editing
    command -v gimp &>/dev/null && apps+="GIMP, "
    command -v inkscape &>/dev/null && apps+="Inkscape, "
    command -v krita &>/dev/null && apps+="Krita, "

    # Video
    command -v obs &>/dev/null && apps+="OBS Studio, "
    command -v kdenlive &>/dev/null && apps+="Kdenlive, "

    # Audio
    command -v audacity &>/dev/null && apps+="Audacity, "

    # Media players
    command -v vlc &>/dev/null && apps+="VLC, "
    command -v mpv &>/dev/null && apps+="mpv, "
    command -v celluloid &>/dev/null && apps+="Celluloid, "

    # Mint media apps
    command -v xplayer &>/dev/null && apps+="Xplayer, "

    AUDIT_CREATIVE="${apps%, }"

    export AUDIT_CREATIVE
}

# ============================================
# PRODUCTIVITY APPS
# ============================================

detect_productivity() {
    AUDIT_PRODUCTIVITY=""
    local apps=""

    # Office
    command -v libreoffice &>/dev/null && apps+="LibreOffice, "

    # Notes/Knowledge
    if command -v flatpak &>/dev/null; then
        flatpak list --app 2>/dev/null | grep -qi obsidian && apps+="Obsidian, "
        flatpak list --app 2>/dev/null | grep -qi notion && apps+="Notion, "
        flatpak list --app 2>/dev/null | grep -qi logseq && apps+="Logseq, "
    fi

    # PDF - Mint ships with xreader
    command -v xreader &>/dev/null && apps+="Xreader, "
    command -v okular &>/dev/null && apps+="Okular, "
    command -v evince &>/dev/null && apps+="Evince, "

    AUDIT_PRODUCTIVITY="${apps%, }"

    export AUDIT_PRODUCTIVITY
}

# ============================================
# UTILITIES
# ============================================

detect_utilities() {
    AUDIT_UTILITIES=""
    local utils=""

    # Security
    if command -v flatpak &>/dev/null; then
        flatpak list --app 2>/dev/null | grep -qi bitwarden && utils+="Bitwarden, "
    fi

    # System - Mint-specific
    command -v timeshift &>/dev/null && utils+="Timeshift, "
    command -v flameshot &>/dev/null && utils+="Flameshot, "
    command -v normcap &>/dev/null && utils+="NormCap, "
    command -v gparted &>/dev/null && utils+="GParted, "

    # File management - Mint default (nemo)
    command -v nemo &>/dev/null && utils+="Nemo, "
    command -v meld &>/dev/null && utils+="Meld, "

    AUDIT_UTILITIES="${utils%, }"

    export AUDIT_UTILITIES
}

# ============================================
# MINT TOOLS
# ============================================

detect_mint_tools() {
    AUDIT_MINT_APPS=""
    local apps=""

    # Mint system tools
    command -v mintupdate &>/dev/null && apps+="Update Manager, "
    command -v mintinstall &>/dev/null && apps+="Software Manager, "
    command -v mintdrivers &>/dev/null && apps+="Driver Manager, "
    command -v mintbackup &>/dev/null && apps+="Backup Tool, "
    command -v mintstick &>/dev/null && apps+="USB Writer, "
    command -v mintreport &>/dev/null && apps+="System Reports, "

    AUDIT_MINT_APPS="${apps%, }"

    export AUDIT_MINT_APPS
}

# ============================================
# VERSION CONTROL
# ============================================

detect_vcs() {
    AUDIT_GIT_VERSION=""
    AUDIT_GH_VERSION=""

    if command -v git &>/dev/null; then
        AUDIT_GIT_VERSION=$(git --version 2>/dev/null | awk '{print $3}')
    fi

    if command -v gh &>/dev/null; then
        AUDIT_GH_VERSION=$(gh --version 2>/dev/null | head -1 | awk '{print $3}')
    fi

    export AUDIT_GIT_VERSION AUDIT_GH_VERSION
}

# ============================================
# SERVICES
# ============================================

detect_services() {
    AUDIT_FAILED_SERVICES=""

    # Get failed services
    local failed=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
    if [ "$failed" -gt 0 ]; then
        AUDIT_FAILED_SERVICES="$failed failed"
    else
        AUDIT_FAILED_SERVICES="All OK"
    fi

    export AUDIT_FAILED_SERVICES
}

# ============================================
# MAIN: RUN ALL DETECTIONS
# ============================================

main() {
    detect_python
    detect_nodejs
    detect_rust
    detect_java
    detect_go
    detect_rust_cli_tools
    detect_containers
    detect_ai_tools
    detect_editors
    detect_browsers
    detect_communication
    detect_creative
    detect_productivity
    detect_utilities
    detect_mint_tools
    detect_vcs
    detect_services
}

# Always run main to populate AUDIT_* variables
main

# Print summary if run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== Software Detection Summary ==="
    echo ""
    echo "Languages:"
    [ -n "$AUDIT_PYTHON_VERSION" ] && echo "  Python: $AUDIT_PYTHON_VERSION ($AUDIT_PYTHON_MANAGER)"
    [ -n "$AUDIT_NODE_VERSION" ] && echo "  Node.js: $AUDIT_NODE_VERSION ($AUDIT_NODE_MANAGER)"
    [ -n "$AUDIT_RUST_VERSION" ] && echo "  Rust: $AUDIT_RUST_VERSION"
    [ -n "$AUDIT_GO_VERSION" ] && echo "  Go: $AUDIT_GO_VERSION"
    [ -n "$AUDIT_JAVA_VERSION" ] && echo "  Java: $AUDIT_JAVA_VERSION"
    echo ""
    echo "Containers:"
    [ -n "$AUDIT_DOCKER_VERSION" ] && echo "  Docker: $AUDIT_DOCKER_VERSION (Running: $AUDIT_DOCKER_RUNNING)"
    [ -n "$AUDIT_PODMAN_VERSION" ] && echo "  Podman: $AUDIT_PODMAN_VERSION"
    [ -n "$AUDIT_DISTROBOX_VERSION" ] && echo "  Distrobox: $AUDIT_DISTROBOX_VERSION"
    echo ""
    echo "AI Tools:"
    [ -n "$AUDIT_OLLAMA_VERSION" ] && echo "  Ollama: $AUDIT_OLLAMA_VERSION (Models: $AUDIT_OLLAMA_MODELS)"
    echo "  Claude Code: $AUDIT_CLAUDE_CODE"
    echo ""
    echo "Mint Tools: $AUDIT_MINT_APPS"
    echo "Rust CLI Tools: $AUDIT_RUST_CLI_TOOLS"
    echo "Browsers: $AUDIT_BROWSERS"
    echo "Editors: $AUDIT_EDITORS"
    echo "Services: $AUDIT_FAILED_SERVICES"
fi
