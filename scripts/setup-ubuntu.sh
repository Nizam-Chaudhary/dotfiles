#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# Ubuntu Guard
# ==========================================================
if ! grep -qi ubuntu /etc/os-release; then
  echo "❌ This script is for Ubuntu only"
  exit 1
fi

# ==========================================================
# Configuration
# ==========================================================
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# ==========================================================
# Enhanced Logging
# ==========================================================
# Colors
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'

log_ts() { date +"%Y-%m-%d %H:%M:%S"; }

log_info() { printf "[%s] ${BLUE}INFO${NC}  %s\n" "$(log_ts)" "$*"; }
log_ok() { printf "[%s] ${GREEN}OK${NC}    %s\n" "$(log_ts)" "$*"; }
log_warn() { printf "[%s] ${YELLOW}WARN${NC}  %s\n" "$(log_ts)" "$*"; }
log_error() { printf "[%s] ${RED}ERROR${NC} %s\n" "$(log_ts)" "$*"; }

section() {
  echo -e "\n${CYAN}══════════════════════════════════════════════════════"
  echo -e " ▶ $1"
  echo -e "══════════════════════════════════════════════════════${NC}"
}

ensure_executable() {
  local script="$1"

  if [[ ! -f "$script" ]]; then
    log_error "$(basename "$script") not found"
    exit 1
  fi

  if [[ ! -x "$script" ]]; then
    log_warn "$(basename "$script") is not executable — fixing"
    chmod +x "$script"
  fi
}

run() {
  log_info "Executing: $*"
  "$@"
}

trap 'log_error "Script failed at line $LINENO"' ERR

# ==========================================================
# Advanced Binary/Command Check
# ==========================================================
# Checks /usr/bin, /usr/local/bin, ~/.local/bin, and current PATH
is_installed() {
  local cmd="$1"
  local extra_paths=(
    "$HOME/.local/bin"
    "$HOME/.local/share/bin"
    "/usr/local/bin"
    "/usr/bin"
  )

  # Check standard PATH first
  if command -v "$cmd" &>/dev/null; then
    return 0
  fi

  # Check specific potential locations not yet in PATH
  for path in "${extra_paths[@]}"; do
    if [[ -x "$path/$cmd" ]]; then
      return 0
    fi
  done

  return 1
}

# ==========================================================
# Prerequisites
# ==========================================================
check_prerequisites() {
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    log_error "Dotfiles directory not found: $DOTFILES_DIR"
    exit 1
  fi
}

sudo_keep_alive() {
  log_info "Requesting sudo privileges..."
  sudo -v
  # Keep-alive: update existing sudo time stamp until script has finished
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}

retry() {
  for _ in {1..3}; do
    "$@" && return
    sleep 2
  done
  return 1
}

# ==========================================================
# Start Setup
# ==========================================================
section "Initialization"
log_ok "Starting Ubuntu Desktop setup 🚀"
check_prerequisites
sudo_keep_alive

# ==========================================================
# System Update & Core Packages
# ==========================================================
section "System Update & Core Packages"
retry sudo apt update
retry sudo apt upgrade -y

CORE_PACKAGES=(
  build-essential
  ca-certificates
  gnupg
  lsb-release
  net-tools
  dnsutils
  software-properties-common
  apt-transport-https
  flatpak
  zsh
  delta
)

sudo apt install -y --no-install-recommends "${CORE_PACKAGES[@]}"

sudo snap install alacritty --classic

# Enable Flathub repository
if ! flatpak remote-list | grep -q flathub; then
  log_info "Adding Flathub remote..."
  run sudo flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
  log_ok "Flathub enabled"
else
  log_info "Flathub already configured"
fi

log_ok "Core packages installed"

# ==========================================================
# Homebrew
# ==========================================================
section "Homebrew"

if ! is_installed brew; then
  log_info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME/.bash_profile"
  log_ok "Homebrew installed"
else
  eval "$(brew shellenv)"
  log_info "Homebrew already installed"
fi

# ==========================================================
# Brew Packages (Modern CLI)
# ==========================================================
section "Brew Packages"

BREW_PACKAGES=(
  fd ripgrep bat eza zoxide mise neovim
  starship fastfetch glow git-delta
  lazygit lazydocker tlrc yazi rip2
  git curl wget zsh vim tmux stow btop htop unzip
  jq tree ncdu rsync aria2 fzf
)

brew install "${BREW_PACKAGES[@]}"
brew install modem-dev/tap/hunk

log_ok "Brew packages installed"

# ==========================================================
# GUI Applications
# ==========================================================
section "GUI Applications"

# Zed
if ! is_installed zed; then
  log_info "Installing Zed..."
  retry curl -f https://zed.dev/install.sh | sh
  log_ok "Zed installed"
else
  log_info "Zed already installed"
fi

# Chrome
if ! is_installed google-chrome; then
  log_info "Installing Google Chrome..."
  wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
  sudo apt install -y /tmp/chrome.deb
  rm /tmp/chrome.deb
  log_ok "Google Chrome installed"
else
  log_info "Google Chrome already installed"
fi

# Flatpak GUI Apps
# FLATPAK_GUI_APPS=(
#   md.obsidian.Obsidian
# )

# log_info "Installing Flatpak GUI applications..."
# flatpak install -y flathub "${FLATPAK_GUI_APPS[@]}"
# log_ok "Flatpak GUI applications installed"

# ==========================================================
# Docker Setup
# ==========================================================
section "Docker Setup"

if ! is_installed docker; then
  log_info "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  sudo systemctl enable docker --now
  log_ok "Docker installed"
else
  log_info "Docker already installed"
fi

# Add user to docker group
if groups "$USER" | grep -q "\bdocker\b"; then
  log_info "User already in docker group"
else
  log_info "Adding $USER to docker group..."
  run sudo usermod -aG docker "$USER"
  log_warn "You will need to log out and back in for docker group changes to take effect"
fi

# ==========================================================
# TPM (tmux plugin manager)
# ==========================================================
section "TPM"

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  log_info "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  log_ok "TPM installed"
else
  log_info "TPM already installed"
fi

# ==========================================================
# Zinit (Plugin Manager for Zsh)
# ==========================================================

section "Zinit Installation"

# Inline directory definition
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  log_info "Installing Zinit to $ZINIT_HOME..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  # sudo chsh -s /usr/bin/zsh "$USER"
  log_ok "Zinit installed successfully"
else
  log_info "Zinit already present; pulling updates..."
  git -C "$ZINIT_HOME" pull --quiet
fi

# Ensure completion cache exists
mkdir -p "$HOME/.zsh/cache"

# ==========================================================
# Install Fonts
# ==========================================================
section "Font Installation"

FONTS_SCRIPT="$DOTFILES_DIR/scripts/install-fonts.sh"

if [[ -f "$FONTS_SCRIPT" ]]; then
  log_info "Installing fonts..."
  ensure_executable "$FONTS_SCRIPT"
  run "$FONTS_SCRIPT"
  log_ok "Fonts installed successfully"
else
  log_warn "install-fonts.sh not found at $FONTS_SCRIPT - skipping font installation"
fi

# ==========================================================
# Atuin Setup (Shell History Manager)
# ==========================================================
# section "Atuin Setup"

# export PATH="$HOME/.local/bin:$PATH"

# if is_installed atuin; then
#   log_ok "Atuin already installed — skipping"
# else
#   log_info "Installing Atuin..."

#   # Official install script
#   run curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

#   log_ok "Atuin installed successfully"
# fi

# ==========================================================
# FNM Setup (Fast Node Manager)
# ==========================================================
# section "FNM Setup"

# if is_installed fnm; then
#   log_ok "fnm already installed — skipping"
# else
#   log_info "Installing fnmm..."

#   # Official install script
#   curl -fsSL https://fnm.vercel.app/install | bash

#   log_ok "fnm installed successfully"
# fi

# ==========================================================
# Dotfiles (stow.sh)
# ==========================================================
section "Dotfiles Setup"

STOW_SCRIPT="$DOTFILES_DIR/scripts/stow.sh"

if [[ -x "$STOW_SCRIPT" ]]; then
  log_info "Running stow.sh (paths, shell config, mise activation)..."
  ensure_executable "$STOW_SCRIPT"
  run "$STOW_SCRIPT"
  log_ok "Dotfiles stowed successfully"
else
  log_error "stow.sh not found or not executable at $STOW_SCRIPT"
fi

# ==========================================================
# Mise Runtime Setup
# ==========================================================
section "Mise Runtime Setup"

export PATH="$HOME/.local/bin:$PATH"

if is_installed mise; then
  log_info "Installing runtimes via mise..."
  mise use -g node@24 bun@latest

  # Activate mise in current shell to make tools available
  log_info "Activating mise environment..."

  # Set PROMPT_COMMAND if not already set (required by mise activate)
  export PROMPT_COMMAND="${PROMPT_COMMAND:-}"

  eval "$(mise activate bash)"

  log_ok "Node.js, Bun and PNPM installed via mise"
else
  log_error "mise not found — runtime setup skipped"
fi

# ==========================================================
# pnpm Shell Completion
# ==========================================================
section "pnpm-shell-completion (Bash + Zsh)"

# --------------------------
# pnpm-shell-completion (bash)
# --------------------------
if [[ -d /usr/share/bash-completion/completions ]]; then
  log_info "Setting up pnpm bash completion..."
  if is_installed pnpm; then
    pnpm completion bash >/tmp/pnpm.bash
    sudo mv /tmp/pnpm.bash /usr/share/bash-completion/completions/pnpm
    log_ok "pnpm bash completion installed"
  else
    log_warn "pnpm not yet available, skipping bash completion"
  fi
else
  log_warn "bash-completion not found, skipping bash completion"
fi

# ==========================================================
# Manual GUI Tools (Not Installed by Script)
# ==========================================================
section "Manual GUI Tools"

cat <<'EOF'
The following tools are NOT installed automatically and must be installed manually:

📦 Database & Dev Tools:
  • DBeaver
      https://dbeaver.io/download/

  • MongoDB Compass
      https://www.mongodb.com/try/download/compass

  • Redis Insight
      https://redis.com/redis-enterprise/redis-insight/

  • TablePlus
      https://tableplus.com/download

📬 API & Testing:
  • Postman
      https://www.postman.com/downloads/

  • Bruno
      https://www.usebruno.com/downloads

📝 Productivity:
  • Obsidian
      https://obsidian.md/download

💻 IDE & Editors:
  • Visual Studio Code
      https://code.visualstudio.com/download

  • Cursor
      https://cursor.sh

🖥️ Terminal:
  • Ghostty (AppImage)
      https://ghostty.org/docs/install/binary#universal-appimage

EOF

# ==========================================================
# Cleanup & Finalize
# ==========================================================
section "Cleanup"

log_info "Cleaning up unnecessary packages..."
sudo apt autoremove -y
sudo apt autoclean

log_ok "Setup Complete 🎉"
log_warn "Please logout or restart your shell to apply all changes."
