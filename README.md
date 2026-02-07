# Mint System Assistant

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
[![Linux Mint](https://img.shields.io/badge/Linux%20Mint-87CF3E?logo=linuxmint&logoColor=white)](https://linuxmint.com/)
[![Cinnamon](https://img.shields.io/badge/Cinnamon-Desktop-orange)](https://github.com/linuxmint/cinnamon)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-orange)](https://claude.ai/code)

An intelligent system assistant for **Linux Mint Cinnamon** — powered by Claude Code with directive-based workflows for security, updates, GPU management, desktop customization, and troubleshooting.

Adapted from [stellar-claude](https://github.com/AgriciDaniel/stellar-claude) (Pop!_OS/COSMIC) for Linux Mint/Cinnamon.

---

## Quick Start

### One-Liner Install
```bash
curl -fsSL https://raw.githubusercontent.com/AgriciDaniel/claude-mint/main/install.sh | bash
```

### Or Clone and Run Locally
```bash
git clone https://github.com/AgriciDaniel/claude-mint.git
cd claude-mint
chmod +x install.sh && ./install.sh
```

---

## What It Does

The `/mint` command gives Claude Code deep knowledge about your Linux Mint system:

| Command | What It Does |
|---------|-------------|
| `/mint` | Interactive menu with system health overview |
| `/mint status` | Full system health report |
| `/mint security` | Security audit with hardening options |
| `/mint update` | Check and apply system updates safely |
| `/mint gpu` | GPU status, drivers, PRIME switching |
| `/mint customize` | Cinnamon desktop configuration |
| `/mint backup` | Timeshift snapshot management |
| `/mint performance` | System performance tuning |
| `/mint troubleshoot` | Diagnose and fix issues |
| `/mint dev` | Development environment setup |

---

## Architecture

Uses a **3-Layer Architecture**:

```
┌─────────────────────────────────┐
│   Skill (SKILL.md)              │  ← Orchestrator + knowledge base
│   /mint command router          │
├─────────────────────────────────┤
│   Directives (8 SOPs)          │  ← Step-by-step procedures
│   security, update, gpu, etc.   │
├─────────────────────────────────┤
│   Execution (bash scripts)      │  ← Audit scripts + profile gen
│   cinnamon.sh, hardware.sh, etc.│
└─────────────────────────────────┘
```

### What Gets Installed

```
~/.claude/
├── CLAUDE.md                    ← Auto-generated system profile
├── skills/mint/SKILL.md         ← Main skill file (/mint command)
├── directives/                  ← 8 SOP directive files
│   ├── security-hardening.md
│   ├── system-update.md
│   ├── cinnamon-customization.md
│   ├── gpu-management.md
│   ├── backup-recovery.md
│   ├── performance-tuning.md
│   ├── troubleshooting.md
│   └── development-setup.md
└── execution/
    ├── audit/
    │   ├── cinnamon.sh          ← Cinnamon/Mint detection
    │   ├── hardware.sh          ← CPU/GPU/RAM/storage
    │   ├── security.sh          ← Security scoring
    │   └── software.sh          ← Dev tools/apps
    └── utils/
        └── generate-profile.sh  ← CLAUDE.md generator
```

---

## Linux Mint Specific Features

This assistant knows about:

- **Cinnamon desktop** — gsettings/dconf configuration, applets, extensions, themes
- **mintupdate-cli** — Safe updates with safety levels (1-5)
- **mintdrivers** — Driver management (NVIDIA, etc.)
- **Timeshift** — Pre-installed backup tool (first-class on Mint)
- **mintbackup** — User data backup
- **GRUB2** — Bootloader configuration
- **prime-select** — NVIDIA/AMD GPU switching
- **powerprofilesctl** — Power profile management
- **X11** — xrandr, xclip, xdotool
- **No Snap** — Mint blocks Snap; Flatpak preferred

---

## Prerequisites

- [Linux Mint](https://linuxmint.com/) 21.x or 22.x (Cinnamon edition)
- [Node.js](https://nodejs.org/) (installer can set this up)
- [Claude Code](https://claude.ai/code) (installer can set this up)

---

## Differences from stellar-claude

| Feature | stellar-claude (Pop!_OS) | claude-mint (Linux Mint) |
|---------|--------------------------|--------------------------|
| Desktop | COSMIC (Wayland) | Cinnamon (X11) |
| Config | RON files | gsettings/dconf |
| Display | cosmic-randr | xrandr |
| Bootloader | systemd-boot + kernelstub | GRUB2 |
| Updates | apt + pop-upgrade | mintupdate-cli + mintupgrade |
| Power | system76-power | powerprofilesctl |
| GPU switch | system76-power graphics | prime-select |
| Recovery | Recovery partition | Timeshift + GRUB |
| Clipboard | wl-copy/wl-paste | xclip/xsel |

---

## License

MIT License — Use freely for personal and commercial projects.

---

## Credits

- Adapted from [stellar-claude](https://github.com/AgriciDaniel/stellar-claude)
- Built for the Linux Mint community
