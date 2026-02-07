# Development Setup Directive

> Triggered by: `/mint dev`

## Goal

Set up and maintain development environments for various languages and tools on Linux Mint Cinnamon.

## Inputs

- Languages/tools the user wants to set up
- Current development environment status

## Tools/Scripts

- `execution/audit/software.sh` - Detect installed dev tools
- Version managers: pyenv, nvm, rustup

## Process

### 1. Assess Current Environment

```bash
source ~/.claude/execution/audit/software.sh
echo "Python: $AUDIT_PYTHON_VERSION ($AUDIT_PYTHON_MANAGER)"
echo "Node.js: $AUDIT_NODE_VERSION ($AUDIT_NODE_MANAGER)"
echo "Rust: $AUDIT_RUST_VERSION"
echo "Docker: $AUDIT_DOCKER_VERSION"
```

### 2. Display Dev Environment Status

```
╔═══════════════════════════════════════════════════════════════╗
║                DEVELOPMENT ENVIRONMENT                         ║
╠═══════════════════════════════════════════════════════════════╣
║ Languages:                                                     ║
║   Python:  [version] via [pyenv/system]                       ║
║   Node.js: [version] via [nvm/system]                         ║
║   Rust:    [version] via rustup                               ║
║   Go:      [version]                                          ║
╠═══════════════════════════════════════════════════════════════╣
║ Tools:                                                         ║
║   Git:     [version]                                          ║
║   Docker:  [version] (running: [yes/no])                      ║
║   Ollama:  [version] (running: [yes/no])                      ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## Language Setup Guides

### Python (via pyenv)

**Install pyenv:**
```bash
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev

curl https://pyenv.run | bash

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
source ~/.bashrc
```

**Install Python version:**
```bash
pyenv install 3.12.4
pyenv global 3.12.4
```

**Note:** Linux Mint (Ubuntu 24.04 base) uses PEP 668 — system Python is "externally managed". Use pyenv or venvs for project work.

---

### Node.js (via nvm or fnm)

**Option 1: nvm (traditional)**
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install --lts
nvm alias default node
```

**Option 2: fnm (faster, recommended)**
```bash
curl -fsSL https://fnm.vercel.app/install | bash
eval "$(fnm env --use-on-cd)"
source ~/.bashrc
fnm install --lts
fnm default lts-latest
```

---

### Rust (via rustup)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install useful tools
cargo install ripgrep fd-find bat eza bottom du-dust
```

---

### Go

```bash
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

---

## Container Setup

### Docker

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER
newgrp docker
```

**Note:** For Linux Mint, use `$UBUNTU_CODENAME` (e.g., `noble`) NOT `$VERSION_CODENAME` (which is the Mint codename like `zena`).

---

### CUDA with Docker (Recommended for ML/AI)

```bash
sudo apt update && sudo apt install nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Test
docker run --rm --gpus all nvidia/cuda:12.4.0-devel-ubuntu22.04 nvidia-smi
```

---

## AI Tools

### Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2
ollama run llama3.2
```

### Claude Code

```bash
curl -fsSL https://claude.ai/install.sh | bash
claude --version
```

---

## Editor Setup

### VS Code

```bash
# Via apt (Microsoft repo) or snap-free install:
sudo apt install code
# Or download .deb from https://code.visualstudio.com/
```

### Neovim

```bash
sudo apt install neovim
# Config: ~/.config/nvim/init.lua
```

---

## Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global init.defaultBranch main
git config --global pull.rebase false

# SSH key for GitHub
ssh-keygen -t ed25519 -C "your@email.com"
cat ~/.ssh/id_ed25519.pub
# Copy to GitHub Settings > SSH Keys

# GitHub CLI
sudo apt install gh
gh auth login
```

---

## Cinnamon Spice Development

Cinnamon supports community add-ons called "Spices":

### Types
- **Applets**: Panel widgets
- **Extensions**: Desktop behavior mods
- **Desklets**: Desktop widgets
- **Themes**: Visual themes

### Development Resources
- **Spices repo**: https://github.com/linuxmint/cinnamon-spices-applets
- **Dev guide**: https://projects.linuxmint.com/reference/git/cinnamon-tutorials/
- **API docs**: https://projects.linuxmint.com/reference/git/cinnamon-js/

### Create a Cinnamon Applet

```bash
# Applets live in ~/.local/share/cinnamon/applets/
mkdir -p ~/.local/share/cinnamon/applets/my-applet@user

# Required files:
# metadata.json - Applet metadata
# applet.js - Main applet code
```

**metadata.json:**
```json
{
    "uuid": "my-applet@user",
    "name": "My Applet",
    "description": "A custom applet",
    "version": "1.0",
    "cinnamon-version": ["6.0"]
}
```

---

## Project Templates

### Python Project
```bash
mkdir my-project && cd my-project
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
```

### Node.js Project
```bash
mkdir my-project && cd my-project
npm init -y
```

### Rust Project
```bash
cargo new my-project
cd my-project
```

---

## Outputs

- Current dev environment status
- Setup instructions for requested tools
- Verification that tools work

## Edge Cases

- **Permission issues**: Check group memberships
- **Path issues**: Verify shell config loaded
- **Version conflicts**: Use version managers
- **PEP 668 error**: Use pyenv or venvs, not system pip

## Safety

- **USE** version managers (pyenv, nvm, rustup)
- **AVOID** system Python for projects (PEP 668)
- **CREATE** virtual environments for Python
- **ADD** user to docker group (not run as root)

## Learnings

<!-- Updated by the agent when new insights are discovered -->
- Linux Mint 22.x is based on Ubuntu 24.04 (noble) — use `$UBUNTU_CODENAME` for Docker repos
- PEP 668 blocks pip install --user; use pyenv or venvs
- pyenv requires build dependencies for compiling Python
- Docker requires logout/login after adding user to group
- **fnm is faster than nvm** — consider it for new setups
- **CUDA + Docker is cleaner** than local CUDA installation
- Cinnamon Spices are the equivalent of GNOME extensions
- VS Code apt package works better than Flatpak for terminal integration
- Linux Mint blocks Snap — install VS Code via apt or .deb download
