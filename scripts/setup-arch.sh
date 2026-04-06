#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# Arch Linux Guard
# ==========================================================
if [[ ! -f /etc/arch-release ]]; then
  echo "❌ This script is for Arch Linux only"
  exit 1
fi

# ==========================================================
# Configuration
# ==========================================================
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
AUR_HELPER="yay"

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

# ==========================================================
# Start Setup
# ==========================================================
section "Initialization"
log_ok "Starting Arch Linux setup 🚀"
check_prerequisites
sudo_keep_alive

# ==========================================================
# System Update & Core Packages
# ==========================================================
section "System Update & Core Packages"
run sudo pacman -Syu --noconfirm

CORE_PACKAGES=(
  base-devel git curl wget zsh neovim vim tmux stow btop htop
  unzip jq tree ncdu rsync fd ripgrep bat eza fzf zoxide mise
  starship fastfetch lazygit git-delta ghostty docker bash-completion
  docker-compose docker-machine docker-buildx flatpak obsidian dbeaver qbittorrent
  lazydocker usbmuxd ifuse libplist gvfs gvfs-afc yazi glow
  gvfs-gphoto2 gvfs-mtp gvfs-smb less
)

sudo pacman -S --noconfirm --needed "${CORE_PACKAGES[@]}"

# ==========================================================
# AUR Helper
# ==========================================================
section "AUR Helper (yay)"
if ! is_installed yay; then
  log_info "Installing yay..."
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  (cd /tmp/yay-bin && makepkg -si --noconfirm)
  rm -rf /tmp/yay-bin
else
  log_info "yay is already installed."
fi

# ==========================================================
# GUI Apps & Zed
# ==========================================================
section "Applications"
AUR_GUI_APPS=(
  visual-studio-code-bin tlrc-bin google-chrome
  postman-bin bruno-bin mongodb-compass-bin redisinsight-bin
)
yay -S --noconfirm --needed "${AUR_GUI_APPS[@]}"

if ! is_installed zed; then
  log_info "Installing Zed..."
  curl -f https://zed.dev/install.sh | sh
else
  log_info "Zed is already installed."
fi

# ==========================================================
# Docker Setup
# ==========================================================

section "Docker Setup"

if is_installed docker; then
  # Enable and start docker service
  if ! systemctl is-active --quiet docker; then
    log_info "Enabling and starting Docker service..."
    run sudo systemctl enable --now docker
  else
    log_info "Docker service is already running"
  fi

  # Add user to docker group
  if groups "$USER" | grep -q "\bdocker\b"; then
    log_info "User already in docker group"
  else
    log_info "Adding $USER to docker group..."
    run sudo usermod -aG docker "$USER"
    log_warn "You will need to log out and back in for docker group changes to take effect"
  fi
else
  log_error "Docker is not installed. Skipping service setup."
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

  sudo chsh -s /usr/bin/zsh "$USER"
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
  run mise install node@22 bun@latest pnpm@latest
  run mise use -g bun@latest pnpm@latest

  # Activate mise in current shell to make tools available
  log_info "Activating mise environment..."

  # Set PROMPT_COMMAND if not already set (required by mise activate)
  export PROMPT_COMMAND="${PROMPT_COMMAND:-}"

  eval "$(mise activate bash)"

  log_ok "Node.js, Bun and PNPM installed via mise"
else
  log_error "mise not found — runtime setup skipped"
fi

# --------------------------
# pnpm-shell-completion (bash)
# --------------------------
if [[ -d /usr/share/bash-completion/completions ]]; then
  log_info "Setting up pnpm bash completion..."
  pnpm completion bash >/tmp/pnpm.bash
  sudo mv /tmp/pnpm.bash /usr/share/bash-completion/completions/pnpm
  log_ok "pnpm bash completion installed"
else
  log_warn "bash-completion not found, skipping bash completion"
fi

# ==========================================================
# Cleanup & Finalize
# ==========================================================
section "Cleanup"
if pacman -Qtdq &>/dev/null; then
  sudo pacman -Rns $(pacman -Qtdq) --noconfirm
fi

log_ok "Setup Complete 🎉"
log_warn "Please logout or restart your shell to apply all changes."
