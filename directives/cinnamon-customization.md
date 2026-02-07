# Cinnamon Customization Directive

> Triggered by: `/mint customize`

## Goal

Safely modify Cinnamon desktop settings. Always backup before changes and verify changes applied correctly.

## Inputs

- User's requested customization
- Current Cinnamon configuration

## Tools/Scripts

- `execution/audit/cinnamon.sh` - Get current Cinnamon config
- `gsettings` / `dconf` - Configuration tools

## Process

### 1. Backup Current Configuration

```bash
# Create timestamped dconf backup
dconf dump /org/cinnamon/ > "$HOME/.config/cinnamon-backup.$(date +%Y%m%d_%H%M%S).dconf"
echo "Backup created"
```

### 2. Show Current Configuration

Display relevant current settings based on user's request.

```bash
# All Cinnamon settings
dconf dump /org/cinnamon/

# Specific schemas
gsettings list-recursively org.cinnamon
gsettings list-recursively org.cinnamon.desktop.interface
gsettings list-recursively org.cinnamon.theme
```

### 3. Common Configuration Areas

| Setting | gsettings Schema | Key |
|---------|-----------------|-----|
| Desktop theme | `org.cinnamon.theme` | `name` |
| Icon theme | `org.cinnamon.desktop.interface` | `icon-theme` |
| GTK theme | `org.cinnamon.desktop.interface` | `gtk-theme` |
| Cursor theme | `org.cinnamon.desktop.interface` | `cursor-theme` |
| Font | `org.cinnamon.desktop.interface` | `font-name` |
| Desktop effects | `org.cinnamon` | `desktop-effects` |
| Hot corners | `org.cinnamon` | `hotcorner-layout` |
| Panel height | dconf `/org/cinnamon/panels-height` | - |
| Workspace count | `org.cinnamon.desktop.wm.preferences` | `num-workspaces` |

### 4. Make the Change

**Theme changes:**
```bash
# Set desktop theme
gsettings set org.cinnamon.theme name "Mint-Y-Dark"

# Set icon theme
gsettings set org.cinnamon.desktop.interface icon-theme "Mint-Y-Dark"

# Set GTK theme
gsettings set org.cinnamon.desktop.interface gtk-theme "Mint-Y-Dark"

# Set cursor theme
gsettings set org.cinnamon.desktop.interface cursor-theme "Adwaita"
```

**Desktop effects:**
```bash
# Disable effects (for performance)
gsettings set org.cinnamon desktop-effects false

# Enable effects
gsettings set org.cinnamon desktop-effects true
```

**Panel configuration:**
```bash
# Change panel height (40px)
dconf write /org/cinnamon/panels-height "['1:40']"

# Auto-hide panel
dconf write /org/cinnamon/panels-autohide "['1:true']"
```

**Keyboard shortcuts (custom):**
```bash
# List current custom keybindings
gsettings get org.cinnamon.desktop.keybindings custom-list

# Add a custom keybinding (via dconf)
# Each binding needs: name, command, binding keys
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/name "'Open Terminal'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/command "'gnome-terminal'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/binding "['<Super>t']"
```

**Applet management:**
```bash
# List enabled applets
gsettings get org.cinnamon enabled-applets

# Extensions
gsettings get org.cinnamon enabled-extensions
```

### 5. Apply Changes

Most gsettings changes apply immediately. For some:

```bash
# Restart Cinnamon (if needed — preserves windows)
cinnamon --replace &

# Or use dbus
dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon org.Cinnamon.Restart
```

### 6. Verify Changes

- Test the new setting
- Confirm it works as expected
- If broken, offer to restore from backup

### 7. Report Result

```
╔═══════════════════════════════════════════════════════════════╗
║                    CUSTOMIZATION APPLIED                       ║
╠═══════════════════════════════════════════════════════════════╣
║ Setting: [what was changed]                                    ║
║ Old value: [previous]                                          ║
║ New value: [current]                                           ║
║ Status: ✓ Applied                                              ║
║ Backup: ~/.config/cinnamon-backup.YYYYMMDD_HHMMSS.dconf       ║
╚═══════════════════════════════════════════════════════════════╝
```

## Common Customizations

### Change Theme (Full Set)

```bash
gsettings set org.cinnamon.theme name "Mint-Y-Dark"
gsettings set org.cinnamon.desktop.interface gtk-theme "Mint-Y-Dark"
gsettings set org.cinnamon.desktop.interface icon-theme "Mint-Y-Dark"
gsettings set org.cinnamon.desktop.wm.preferences theme "Mint-Y-Dark"
```

### Install Cinnamon Spices (Applets/Extensions/Themes)

Cinnamon Spices are community add-ons:
- **Applets**: Panel widgets (system monitor, weather, etc.)
- **Extensions**: Desktop behavior modifications
- **Desklets**: Desktop widgets
- **Themes**: Visual themes

```bash
# Install via GUI: System Settings > Applets/Extensions/Themes > Download tab
# Or browse: https://cinnamon-spices.linuxmint.com/
```

### Enable/Disable Desktop Effects

```bash
# Toggle effects
gsettings set org.cinnamon desktop-effects false  # Disable (performance)
gsettings set org.cinnamon desktop-effects true   # Enable (aesthetics)
```

### Configure Hot Corners

```bash
# Get current layout
gsettings get org.cinnamon hotcorner-layout

# Set (format: topleft:action:delay, topright:action:delay, etc.)
# Actions: expo, scale, desktop, custom
gsettings set org.cinnamon hotcorner-layout "['expo:false:0', 'scale:false:0', 'desktop:false:0', ':false:0']"
```

### Set Custom Wallpaper

```bash
gsettings set org.cinnamon.desktop.background picture-uri "file:///path/to/wallpaper.jpg"
gsettings set org.cinnamon.desktop.background picture-options "zoom"
```

## Outputs

- Confirmation of change
- Backup location
- How to revert if needed

## Edge Cases

- **If gsettings key doesn't exist**: Check schema with `gsettings list-keys SCHEMA`
- **If change doesn't apply**: Run `cinnamon --replace &`
- **If Cinnamon crashes**: Switch to TTY (Ctrl+Alt+F3), run `cinnamon --replace &`
- **If complete reset needed**: `dconf reset -f /org/cinnamon/`

## Safety

- **ALWAYS** backup dconf before any config change
- **NEVER** modify system-wide Cinnamon configs (only user configs)
- **TEST** changes before reporting success
- **PROVIDE** rollback instructions

## Rollback Instructions

```bash
# Restore from dconf backup
dconf load /org/cinnamon/ < ~/.config/cinnamon-backup.YYYYMMDD_HHMMSS.dconf

# Restart Cinnamon
cinnamon --replace &

# Nuclear option: reset all Cinnamon settings
dconf reset -f /org/cinnamon/
```

## Learnings

<!-- Updated by the agent when new insights are discovered -->
- Cinnamon config uses gsettings/dconf (not RON files like COSMIC)
- Most changes apply live without restart
- `cinnamon --replace &` restarts the desktop without losing windows
- dconf backup/restore is the safest way to manage config changes
- Cinnamon Spices (applets/extensions) can be installed from GUI or cinnamon-spices.linuxmint.com
- Hot corners are configured per-corner with action and delay
