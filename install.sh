#!/bin/bash
# Mint System Assistant Installer
# One-liner: curl -fsSL https://raw.githubusercontent.com/AgriciDaniel/claude-mint/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================
# HELPER FUNCTIONS
# ============================================

print_header() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║             MINT SYSTEM ASSISTANT INSTALLER                    ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# ============================================
# VERIFICATION
# ============================================

verify_mint() {
    if [ ! -f /etc/os-release ]; then
        print_error "Cannot detect operating system"
        exit 1
    fi

    . /etc/os-release

    if [[ "$ID" != "linuxmint" ]]; then
        print_error "This installer is for Linux Mint only."
        print_error "Detected: $PRETTY_NAME"
        exit 1
    fi

    print_status "Detected: $PRETTY_NAME"
}

verify_cinnamon() {
    if pgrep -x "cinnamon" > /dev/null 2>&1; then
        print_status "Cinnamon desktop environment detected"
        return 0
    fi

    if command -v cinnamon &>/dev/null; then
        print_warning "Cinnamon installed but not running as current session"
        return 0
    fi

    print_warning "Cinnamon desktop not detected (may work anyway)"
    return 0
}

# ============================================
# INSTALLATION
# ============================================

install_node_if_needed() {
    if command -v node &>/dev/null; then
        local version=$(node --version 2>/dev/null)
        print_status "Node.js already installed: $version"
        return 0
    fi

    print_status "Installing Node.js via nvm..."

    # Install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install LTS Node
    nvm install --lts
    nvm use --lts

    print_status "Node.js installed: $(node --version)"
}

install_claude_code() {
    if command -v claude &>/dev/null; then
        print_status "Claude Code already installed"
        return 0
    fi

    print_status "Installing Claude Code via official installer..."
    curl -fsSL https://claude.ai/install.sh | bash

    # Add common Claude Code paths to current session
    export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

    if command -v claude &>/dev/null; then
        print_status "Claude Code installed"
    else
        print_warning "Claude Code installed but may need terminal restart"
    fi
}

create_directory_structure() {
    print_status "Creating directory structure..."

    mkdir -p ~/.claude/skills/mint
    mkdir -p ~/.claude/directives
    mkdir -p ~/.claude/execution/audit
    mkdir -p ~/.claude/execution/actions
    mkdir -p ~/.claude/execution/utils
}

install_skill_and_scripts() {
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Check if running from repo or curl
    if [ -f "$SCRIPT_DIR/skills/mint/SKILL.md" ]; then
        # Running from local repo
        print_status "Installing from local repository..."

        # Copy skill
        cp "$SCRIPT_DIR/skills/mint/SKILL.md" ~/.claude/skills/mint/

        # Copy directives
        cp "$SCRIPT_DIR/directives/"*.md ~/.claude/directives/ 2>/dev/null || true

        # Copy execution scripts
        cp "$SCRIPT_DIR/execution/audit/"*.sh ~/.claude/execution/audit/ 2>/dev/null || true
        cp "$SCRIPT_DIR/execution/utils/"*.sh ~/.claude/execution/utils/ 2>/dev/null || true

        # Make scripts executable
        chmod +x ~/.claude/execution/audit/*.sh 2>/dev/null || true
        chmod +x ~/.claude/execution/utils/*.sh 2>/dev/null || true
    else
        # Running from curl - download from GitHub
        print_status "Downloading from GitHub..."

        local REPO_URL="https://raw.githubusercontent.com/AgriciDaniel/claude-mint/main"

        # Download skill
        curl -fsSL "$REPO_URL/skills/mint/SKILL.md" -o ~/.claude/skills/mint/SKILL.md

        # Download directives
        for directive in security-hardening system-update cinnamon-customization gpu-management backup-recovery performance-tuning troubleshooting development-setup; do
            curl -fsSL "$REPO_URL/directives/${directive}.md" -o ~/.claude/directives/${directive}.md 2>/dev/null || true
        done

        # Download execution scripts
        for script in hardware security cinnamon software; do
            curl -fsSL "$REPO_URL/execution/audit/${script}.sh" -o ~/.claude/execution/audit/${script}.sh
            chmod +x ~/.claude/execution/audit/${script}.sh
        done

        curl -fsSL "$REPO_URL/execution/utils/generate-profile.sh" -o ~/.claude/execution/utils/generate-profile.sh
        chmod +x ~/.claude/execution/utils/generate-profile.sh
    fi

    print_status "Installed /mint skill and scripts"
}

# ============================================
# SYSTEM AUDIT
# ============================================

run_system_audit() {
    print_status "Running system audit..."

    # Source audit scripts
    source ~/.claude/execution/audit/hardware.sh 2>/dev/null || true
    source ~/.claude/execution/audit/security.sh 2>/dev/null || true
    source ~/.claude/execution/audit/cinnamon.sh 2>/dev/null || true
    source ~/.claude/execution/audit/software.sh 2>/dev/null || true

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      SYSTEM AUDIT                              ║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} CPU:        ${AUDIT_CPU_MODEL:-Unknown} (${AUDIT_CPU_CORES:-?}C/${AUDIT_CPU_THREADS:-?}T)"
    echo -e "${CYAN}║${NC} RAM:        ${AUDIT_RAM_TOTAL:-Unknown}"
    echo -e "${CYAN}║${NC} GPU:        ${AUDIT_GPU_MODEL:-Unknown}"
    [ -n "$AUDIT_GPU_SECONDARY" ] && echo -e "${CYAN}║${NC} GPU 2:      ${AUDIT_GPU_SECONDARY}"
    echo -e "${CYAN}║${NC} Storage:    ${AUDIT_STORAGE_MODEL:-Unknown} (${AUDIT_STORAGE_SIZE:-?})"
    echo -e "${CYAN}║${NC} Cinnamon:   ${AUDIT_CINNAMON_VERSION:-Unknown}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Security Score: ${AUDIT_SECURITY_SCORE:-??}/100"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================
# PROFILE GENERATION
# ============================================

generate_profile() {
    print_status "Generating system profile..."

    # Backup existing profile
    if [ -f ~/.claude/CLAUDE.md ]; then
        local backup="$HOME/.claude/CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"
        cp ~/.claude/CLAUDE.md "$backup"
        print_status "Backed up existing profile to $backup"
    fi

    # Generate new profile
    if [ -x ~/.claude/execution/utils/generate-profile.sh ]; then
        ~/.claude/execution/utils/generate-profile.sh > ~/.claude/CLAUDE.md
        print_status "Generated ~/.claude/CLAUDE.md"
    else
        print_warning "Profile generator not found, skipping profile generation"
    fi
}

# ============================================
# OPTIONAL HARDENING
# ============================================

offer_hardening() {
    # Only offer if score is below threshold
    if [ "${AUDIT_SECURITY_SCORE:-0}" -ge 85 ]; then
        print_status "Security score is good (${AUDIT_SECURITY_SCORE}/100)"
        return 0
    fi

    # Skip interactive prompts when running under curl|bash (stdin is the pipe)
    if [ ! -t 0 ]; then
        print_warning "Security score is ${AUDIT_SECURITY_SCORE}/100. Run install.sh directly for hardening options."
        return 0
    fi

    echo ""
    echo -e "${YELLOW}Your security score is ${AUDIT_SECURITY_SCORE}/100${NC}"
    echo "Would you like to enable basic security hardening?"
    echo "  - Enable UFW firewall"
    echo "  - Enable automatic security updates"
    echo ""
    read -p "Enable hardening? (y/N) " -n 1 -r </dev/tty
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Enabling firewall..."
        sudo ufw default deny incoming 2>/dev/null || true
        sudo ufw default allow outgoing 2>/dev/null || true
        sudo ufw --force enable 2>/dev/null || true

        print_status "Enabling auto-updates..."
        sudo apt install -y unattended-upgrades 2>/dev/null || true
        sudo dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || true

        print_status "Security hardening applied"
    fi
}

# ============================================
# FINAL SUMMARY
# ============================================

print_summary() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 INSTALLATION COMPLETE                          ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} ✓ Installed /mint skill to ~/.claude/skills/mint/"
    echo -e "${GREEN}║${NC} ✓ Installed directives to ~/.claude/directives/"
    echo -e "${GREEN}║${NC} ✓ Installed scripts to ~/.claude/execution/"
    echo -e "${GREEN}║${NC} ✓ Generated system profile: ~/.claude/CLAUDE.md"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} Use ${CYAN}/mint${NC} in Claude Code to get started!"
    echo -e "${GREEN}║${NC}"
    echo -e "${GREEN}║${NC} Available commands:"
    echo -e "${GREEN}║${NC}   /mint              Interactive menu"
    echo -e "${GREEN}║${NC}   /mint security     Security audit"
    echo -e "${GREEN}║${NC}   /mint update       System updates"
    echo -e "${GREEN}║${NC}   /mint gpu          GPU management"
    echo -e "${GREEN}║${NC}   /mint customize    Cinnamon customization"
    echo -e "${GREEN}║${NC}   /mint troubleshoot Diagnose issues"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================
# MAIN
# ============================================

main() {
    print_header

    # Verification
    verify_mint
    verify_cinnamon

    # Installation
    install_node_if_needed
    install_claude_code
    create_directory_structure
    install_skill_and_scripts

    # Audit and profile
    run_system_audit
    generate_profile

    # Optional hardening
    offer_hardening

    # Summary
    print_summary
}

# Run
main "$@"
