#!/bin/bash
# setup-prerequisites.sh - Install Claude Code, VS Code, and essential extensions
# Part of Mint System Assistant
# Based on: https://github.com/AgriciDaniel/claude-code-essentials-vs-code

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        CLAUDE CODE & VS CODE SETUP FOR LINUX MINT             ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_step() {
    echo ""
    echo -e "${CYAN}━━━ Step $1: $2 ━━━${NC}"
}

verify_mint() {
    if [ ! -f /etc/os-release ]; then
        print_error "Cannot detect operating system"
        exit 1
    fi
    . /etc/os-release
    if [[ "$ID" != "linuxmint" ]]; then
        print_warning "This script is optimized for Linux Mint."
        print_warning "Detected: $PRETTY_NAME"
        read -p "Continue anyway? (y/N) " -n 1 -r </dev/tty
        echo ""
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    else
        print_status "Detected: $PRETTY_NAME"
    fi
}

install_nodejs() {
    print_step "1" "Node.js Installation"
    if command -v node &>/dev/null; then
        print_status "Node.js already installed: $(node --version)"
        return 0
    fi
    print_status "Installing Node.js via nvm..."
    export NVM_DIR="$HOME/.nvm"
    [ ! -d "$NVM_DIR" ] && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    nvm alias default node
    print_status "Node.js installed: $(node --version)"
}

install_vscode() {
    print_step "2" "VS Code Installation"
    if command -v code &>/dev/null; then
        print_status "VS Code already installed: $(code --version | head -1)"
        return 0
    fi
    print_status "Installing VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f /tmp/packages.microsoft.gpg
    sudo apt update
    sudo apt install -y code
    print_status "VS Code installed: $(code --version | head -1)"
}

install_vscode_extensions() {
    print_step "3" "VS Code Extensions"
    if ! command -v code &>/dev/null; then
        print_warning "VS Code not found, skipping extensions"
        return 1
    fi
    local extensions=(
        "anthropic.claude-code"
        "github.copilot"
        "ms-python.python"
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
        "eamodio.gitlens"
        "mhutchie.git-graph"
        "streetsidesoftware.code-spell-checker"
        "formulahendry.auto-rename-tag"
        "christian-kohler.path-intellisense"
        "pkief.material-icon-theme"
        "ms-vscode-remote.remote-ssh"
        "bradlc.vscode-tailwindcss"
    )
    local installed=0
    for ext in "${extensions[@]}"; do
        if code --install-extension "$ext" --force &>/dev/null; then
            print_status "Installed: $ext"
            ((installed++))
        else
            print_warning "Failed: $ext"
        fi
    done
    print_status "Extensions installed: $installed"
}

install_claude_code() {
    print_step "4" "Claude Code CLI"
    if command -v claude &>/dev/null; then
        print_status "Claude Code already installed: $(claude --version 2>/dev/null || echo 'installed')"
        return 0
    fi
    curl -fsSL https://claude.ai/install.sh | bash
    export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
    if command -v claude &>/dev/null; then
        print_status "Claude Code installed"
    else
        print_warning "Claude Code installed but not in PATH — restart terminal"
    fi
}

print_summary() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    SETUP COMPLETE                              ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    command -v node &>/dev/null && echo -e "${GREEN}║${NC} ✓ Node.js: $(node --version)" || echo -e "${GREEN}║${NC} ✗ Node.js: Not installed"
    if command -v code &>/dev/null; then
        echo -e "${GREEN}║${NC} ✓ VS Code: $(code --version | head -1)"
        echo -e "${GREEN}║${NC}   Extensions: $(code --list-extensions 2>/dev/null | wc -l) installed"
    fi
    command -v claude &>/dev/null && echo -e "${GREEN}║${NC} ✓ Claude Code: $(claude --version 2>/dev/null || echo 'installed')" || echo -e "${GREEN}║${NC} ✗ Claude Code: Not installed"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} Next: Run the Mint System Assistant installer:"
    echo -e "${GREEN}║${NC}   ${CYAN}cd ~/claude-mint && chmod +x install.sh && ./install.sh${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

main() {
    print_header
    verify_mint
    install_nodejs
    install_vscode
    install_vscode_extensions
    install_claude_code
    print_summary
}

main "$@"
