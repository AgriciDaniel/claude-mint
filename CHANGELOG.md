# Changelog

## v1.0.0 (2026-02-07)

### Initial Release
- Adapted from stellar-claude (Pop!_OS/COSMIC) for Linux Mint Cinnamon
- Full Cinnamon/X11 knowledge base
  - gsettings/dconf configuration (replaces COSMIC RON files)
  - xrandr display management (replaces cosmic-randr)
  - Cinnamon applets, extensions, themes, desklets
- Linux Mint-specific tools
  - mintupdate-cli with safety levels
  - mintdrivers for driver management
  - mintbackup for user data
  - mintupgrade for release upgrades
- GRUB2 bootloader support (replaces systemd-boot/kernelstub)
- powerprofilesctl for power management (replaces system76-power)
- prime-select for GPU switching (replaces system76-power graphics)
- X11 clipboard tools: xclip, xsel, xdotool (replaces wl-copy/wl-paste)
- Timeshift as primary backup (no recovery partition dependency)
- Secure Boot with MOK enrollment support
- 4 audit scripts: cinnamon.sh, hardware.sh, security.sh, software.sh
- 8 directive files for guided workflows
- System profile generator (CLAUDE.md)
- Installer with system audit and optional hardening
