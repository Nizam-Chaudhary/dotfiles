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
# WSL Detection
# ==========================================================
is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

# ==========================================================
# Configuration
# ==========================================================
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# ==========================================================
# Enhanced Logging
# ==========================================================
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'

log_ts() { date +"%Y-%m-%d %H:%M:%S"; }

log_info() { printf "[%s] ${BLUE}INFO${NC}  %s\n" "$(log_ts)" "$*"; }
log_ok()   { printf "[%s] ${GREEN}OK${NC}    %s\n" "$(log_ts)" "$*"; }
log_warn() { printf "[%s] ${YELLOW}WARN${NC}  %s\n" "$(log_ts)" "$*"; }
log_error(){ printf "[%s] ${RED}ERROR${NC} %s\n" "$(log_ts)" "$*"; }

section() {
  echo -e "\n${CYAN}══════════════════════════════════════════════════════"
  echo -e " ▶ $1"
  echo -e "══════════════════════════════════════════════════════${NC}"
}

trap 'log_error "Script failed at line $LINENO"' ERR

run() {
  log_info "Executing: $*"
  "$@"
}

# ==========================================================
# Command Check
# ==========================================================
is_installed() {
  command -v "$1" &>/dev/null
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
  sudo -v
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
# Initialization
# ==========================================================
section "Initialization"
log_ok "Starting Ubuntu setup 🚀"
check_prerequisites

if is_wsl; then
  log_info "WSL detected — skipping sudo keep-alive"
else
  sudo_keep_alive
fi

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
  zsh
  delta
)

sudo apt install -y --no-install-recommends "${CORE_PACKAGES[@]}"
log_ok "Core packages installed"

# ==========================================================
# Homebrew
# ==========================================================
section "Homebrew"

BREW_ENV='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'

if ! is_installed brew; then
  log_info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

grep -qxF "$BREW_ENV" "$HOME/.bashrc" || echo "$BREW_ENV" >>"$HOME/.bashrc"
grep -qxF "$BREW_ENV" "$HOME/.bash_profile" || echo "$BREW_ENV" >>"$HOME/.bash_profile"

log_ok "Homebrew ready"

# ==========================================================
# Brew Packages
# ==========================================================
section "Brew Packages"

BREW_PACKAGES=(
  fd ripgrep bat eza zoxide mise neovim
  starship fastfetch glow
  lazygit tlrc yazi rip2
  git curl wget zsh vim tmux stow
  btop htop unzip jq tree ncdu rsync
  aria2  fzf
)

brew install "${BREW_PACKAGES[@]}"

log_ok "Brew packages installed"

# ==========================================================
# TPM (tmux plugin manager)
# ==========================================================
section "TPM"

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  log_ok "TPM installed"
else
  log_info "TPM already installed"
fi

# ==========================================================
# Zinit
# ==========================================================
section "Zinit"

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  # sudo chsh -s /usr/bin/zsh "$USER" || log_warn "chsh failed (expected on WSL)"
  log_ok "Zinit installed"
else
  git -C "$ZINIT_HOME" pull --quiet
  log_info "Zinit updated"
fi

mkdir -p "$HOME/.zsh/cache"

# ==========================================================
# Atuin
# ==========================================================
# section "Atuin"

# export PATH="$HOME/.local/bin:$PATH"

# if ! is_installed atuin; then
#   curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
#   log_ok "Atuin installed"
# else
#   log_info "Atuin already installed"
# fi

# ==========================================================
# FNM Setup (Fast Node Manager)
# ==========================================================
section "FNM Setup"

if is_installed fnm; then
  log_ok "fnm already installed — skipping"
else
  log_info "Installing fnmm..."

  # Official install script
  curl -fsSL https://fnm.vercel.app/install | bash

  log_ok "fnm installed successfully"
fi

# ==========================================================
# Dotfiles
# ==========================================================
section "Dotfiles"

STOW_SCRIPT="$DOTFILES_DIR/scripts/stow.sh"

if [[ -x "$STOW_SCRIPT" ]]; then
  run "$STOW_SCRIPT"
  log_ok "Dotfiles stowed"
else
  log_error "stow.sh not executable: $STOW_SCRIPT"
fi

# ==========================================================
# Mise Runtime Setup
# ==========================================================
section "Mise"

if is_installed mise; then
  mise install node@22 bun@latest pnpm@latest
  mise use -g node@22 bun@latest pnpm@latest
  eval "$(mise activate bash)"
  log_ok "Node, Bun, PNPM installed via mise"
else
  log_warn "mise not found — skipping runtimes"
fi

# ==========================================================
# pnpm Completion
# ==========================================================
section "pnpm Completion"

if is_installed pnpm && [[ -d /usr/share/bash-completion/completions ]]; then
  pnpm completion bash | sudo tee /usr/share/bash-completion/completions/pnpm >/dev/null
  log_ok "pnpm bash completion installed"
else
  log_warn "pnpm or bash-completion missing — skipping"
fi

# ==========================================================
# Health Check
# ==========================================================
section "Health Check"

for cmd in git zsh node pnpm bun tmux nvim mise brew; do
  is_installed "$cmd" && log_ok "$cmd OK" || log_warn "$cmd missing"
done

if is_wsl; then
  log_info "Docker handled externally via Docker Desktop (WSL integration)"
fi

# ==========================================================
# Cleanup
# ==========================================================
section "Cleanup"

sudo apt autoremove -y
sudo apt autoclean

log_ok "Setup Complete 🎉"
log_warn "Restart your shell or WSL session to apply all changes"
