#!/usr/bin/env bash
set -Eeo pipefail

# ==========================================================
# Dotfiles Stow with Tar.gz Backup
# ==========================================================

# ==========================================================
# Enhanced Logging
# ==========================================================
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'

log_ts() { date +"%Y-%m-%d %H:%M:%S"; }

log_info() { printf "${GRAY}[%s]${NC} ${BLUE}▸${NC} %s\n" "$(log_ts)" "$*" >&2; }
log_ok() { printf "${GRAY}[%s]${NC} ${GREEN}✓${NC} %s\n" "$(log_ts)" "$*" >&2; }
log_warn() { printf "${GRAY}[%s]${NC} ${YELLOW}⚠${NC} %s\n" "$(log_ts)" "$*" >&2; }
log_error() { printf "${GRAY}[%s]${NC} ${RED}✗${NC} %s\n" "$(log_ts)" "$*" >&2; }
log_skip() { printf "${GRAY}[%s]${NC} ${GRAY}⊘${NC} %s\n" "$(log_ts)" "$*" >&2; }

section() {
  echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo -e "${CYAN}▶${NC} ${BLUE}$1${NC}" >&2
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
}

error_handler() {
  local line_number=$1
  log_error "Script failed at line $line_number"
  log_error "Last command: $BASH_COMMAND"
  exit 1
}

trap 'error_handler $LINENO' ERR

# ==========================================================
# Configuration
# ==========================================================
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

STOW_PACKAGES=(
  alacritty
  bash
  bat
  browser-flags
  btop
  chromium
  eza
  fastfetch
  fontconfig
  ghostty
  git
  kitty
  lazydocker
  lazygit
  nvim
  opencode
  starship
  tmux
  typora
  yazi
  zed
  zsh
  hunk
)

# ==========================================================
# Backup Configuration
# ==========================================================
BACKUP_TIME="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$HOME/dotfiles_backup"
BACKUP_ARCHIVE="$BACKUP_DIR/dotfiles_backup_$BACKUP_TIME.tar.gz"
BACKUP_STAGING="$BACKUP_DIR/.staging_$BACKUP_TIME"

# ==========================================================
# Stow History
# ==========================================================
STATE_DIR="$HOME/dotfiles"
HISTORY_FILE="$STATE_DIR/.stow-history"

mkdir -p "$STATE_DIR"
touch "$HISTORY_FILE"

is_in_history() {
  grep -Fxq "$1" "$HISTORY_FILE" 2>/dev/null || return 1
}

add_to_history() {
  if ! grep -Fxq "$1" "$HISTORY_FILE" 2>/dev/null; then
    echo "$1" >>"$HISTORY_FILE"
  fi
}

# ==========================================================
# Symlink Detection
# ==========================================================
is_our_symlink() {
  local path="$1"
  if [[ -L "$path" ]]; then
    local target
    target="$(readlink "$path" 2>/dev/null || echo "")"
    # Check if target starts with our repo path (can be relative or absolute)
    if [[ -n "$target" ]]; then
      # Resolve to absolute path for comparison
      local abs_target="$(cd "$(dirname "$path")" && readlink -f "$path" 2>/dev/null || echo "")"
      [[ -n "$abs_target" && "$abs_target" == "$REPO_ROOT"* ]] && return 0
    fi
  fi
  return 1
}

check_symlink_at_path() {
  local pkg="$1"
  local rel_path="$2" # relative path from package (e.g., ".config/alacritty")
  local check_path="$HOME/$rel_path"

  # If it's a symlink pointing to our repo, it's linked
  if is_our_symlink "$check_path"; then
    return 0
  fi

  # If it's a directory (not symlink), check if it contains our symlinks
  if [[ -d "$check_path" && ! -L "$check_path" ]]; then
    # Directory exists but isn't a symlink - check contents
    local pkg_source="$REPO_ROOT/$pkg/$rel_path"

    # Check all items that should be in this directory
    if [[ -d "$pkg_source" ]]; then
      local all_items_linked=true
      local has_items=false

      while IFS= read -r -d '' item; do
        [[ -z "$item" ]] && continue
        has_items=true

        local item_name="$(basename "$item")"
        local item_dest="$check_path/$item_name"

        # Recursively check this item
        if ! check_symlink_at_path "$pkg" "$rel_path/$item_name"; then
          all_items_linked=false
          break
        fi
      done < <(find "$pkg_source" -mindepth 1 -maxdepth 1 -print0 2>/dev/null || true)

      # If we found items and they're all linked, consider this path linked
      [[ "$has_items" == "true" && "$all_items_linked" == "true" ]] && return 0
    fi
  fi

  # If it's a file, it must be a symlink to be considered linked
  if [[ -f "$check_path" && ! -L "$check_path" ]]; then
    return 1
  fi

  # Path doesn't exist - not linked
  [[ ! -e "$check_path" ]] && return 1

  # Default: not linked
  return 1
}

has_all_symlinks() {
  local pkg="$1"

  if [[ ! -d "$pkg" ]]; then
    return 1
  fi

  local all_linked=true
  local has_content=false

  # Check each top-level item in the package directory
  while IFS= read -r -d '' item; do
    [[ -z "$item" ]] && continue
    has_content=true

    local name="$(basename "$item")"

    # Check if this item is properly symlinked
    if ! check_symlink_at_path "$pkg" "$name"; then
      all_linked=false
      break
    fi
  done < <(find "$pkg" -mindepth 1 -maxdepth 1 -print0 2>/dev/null || true)

  # Return true only if we found content AND everything is linked
  [[ "$has_content" == "true" && "$all_linked" == "true" ]]
}

# ==========================================================
# Package Analysis
# ==========================================================
declare -a TO_STOW
declare -a TO_UNSTOW_FIRST
declare -a ALREADY_DONE
declare -a ALREADY_LINKED

has_any_symlinks() {
  local pkg="$1"

  if [[ ! -d "$pkg" ]]; then
    return 1
  fi

  # Check if ANY symlink from this package exists
  while IFS= read -r -d '' item; do
    [[ -z "$item" ]] && continue

    local name="$(basename "$item")"
    local rel="${item#$pkg/}"
    local check_path="$HOME/$rel"

    # If we find any symlink pointing to our repo, return true
    if is_our_symlink "$check_path"; then
      return 0
    fi
  done < <(find "$pkg" -mindepth 1 -maxdepth 1 -print0 2>/dev/null || true)

  return 1
}

analyze_packages() {
  section "Analyzing Packages"

  for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ ! -d "$pkg" ]]; then
      log_warn "Package not found: $pkg"
      continue
    fi

    # If already in history, skip symlink check - trust the history
    if is_in_history "$pkg"; then
      log_skip "Already stowed: $pkg (in history)"
      ALREADY_DONE+=("$pkg")
      continue
    fi

    # Not in history - check if symlinks already exist
    if has_all_symlinks "$pkg"; then
      log_skip "Already linked: $pkg (adding to history)"
      add_to_history "$pkg"
      ALREADY_LINKED+=("$pkg")
    else
      # Check if we need to unstow first (partial symlinks exist)
      if has_any_symlinks "$pkg"; then
        log_info "Partial symlinks found: $pkg (will unstow, backup, then stow)"
        TO_UNSTOW_FIRST+=("$pkg")
      else
        log_info "New package: $pkg (will stow)"
      fi
      TO_STOW+=("$pkg")
    fi
  done

  echo >&2
  log_ok "Analysis complete: ${#TO_STOW[@]} new, ${#ALREADY_DONE[@]} skip, ${#ALREADY_LINKED[@]} auto-added"
  if [[ ${#TO_UNSTOW_FIRST[@]} -gt 0 ]]; then
    log_info "Will unstow first: ${#TO_UNSTOW_FIRST[@]} package(s) with existing symlinks"
  fi
}

# ==========================================================
# Backup
# ==========================================================
declare -a BACKUP_LIST

stage_for_backup() {
  local path="$1"

  if [[ ! -e "$path" && ! -L "$path" ]]; then
    return
  fi

  # Skip if it's already our symlink
  if is_our_symlink "$path"; then
    return
  fi

  local rel="${path#$HOME/}"
  local dest="$BACKUP_STAGING/$rel"

  mkdir -p "$(dirname "$dest")"
  if cp -a "$path" "$dest" 2>/dev/null; then
    BACKUP_LIST+=("$path")
  else
    log_warn "Failed to backup: $path"
  fi
}

list_stow_targets() {
  local pkg="$1"

  find "$pkg" -mindepth 1 -maxdepth 1 -print0
}

safe_remove() {
  local path="$1"

  case "$path" in
  "$HOME/.config" | "$HOME" | "/")
    log_error "Refusing to remove dangerous path: $path"
    return 1
    ;;
  esac

  rm -rf "$path"
}

backup_paths_for_package() {
  local pkg="$1"
  local count=0

  while IFS= read -r -d '' src; do
    local rel="${src#$pkg/}"
    local dest="$HOME/$rel"

    # ❗️Never backup parent directories
    if [[ "$dest" == "$HOME/.config" ]]; then
      continue
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
      if ! is_our_symlink "$dest"; then
        stage_for_backup "$dest"
        BACKUP_LIST+=("$dest")
        ((++count))
      fi
    fi
  done < <(list_stow_targets "$pkg")

  if ((count > 0)); then
    log_info "Backed up $count item(s) from: $pkg"
  else
    log_skip "No items to backup for: $pkg"
  fi
}

create_backup_archive() {
  if [[ ! -d "$BACKUP_STAGING" ]] || [[ -z "$(ls -A "$BACKUP_STAGING" 2>/dev/null)" ]]; then
    log_skip "No files to backup"
    rm -rf "$BACKUP_STAGING" 2>/dev/null || true
    return
  fi

  mkdir -p "$BACKUP_DIR"

  if tar -czf "$BACKUP_ARCHIVE" -C "$BACKUP_STAGING" . 2>/dev/null; then
    log_ok "Backup created: $BACKUP_ARCHIVE ($(du -h "$BACKUP_ARCHIVE" | cut -f1))"
  else
    log_error "Failed to create backup archive"
  fi

  rm -rf "$BACKUP_STAGING" 2>/dev/null || true
}

remove_backed_up_files() {
  if [[ ${#BACKUP_LIST[@]} -eq 0 ]]; then
    return
  fi

  for path in "${BACKUP_LIST[@]}"; do
    if [[ -e "$path" || -L "$path" ]]; then
      safe_remove "$path" || log_warn "Failed to remove: $path"
    fi
  done

  log_ok "Removed ${#BACKUP_LIST[@]} backed up item(s)"
}

# ==========================================================
# Stow Operations
# ==========================================================
do_unstow() {
  local pkg="$1"
  stow --delete --target="$HOME" "$pkg" 2>/dev/null || true
}

do_stow() {
  local pkg="$1"

  if stow --target="$HOME" "$pkg" 2>/dev/null; then
    add_to_history "$pkg"
    return 0
  else
    log_error "Failed to stow: $pkg"
    return 1
  fi
}

# ==========================================================
# Main Execution
# ==========================================================
main() {
  section "Dotfiles Stow Manager"
  log_info "Repository: $REPO_ROOT"
  log_info "Backup archive: $BACKUP_ARCHIVE"

  # Step 1: Analyze all packages
  analyze_packages

  # Check if there's work to do
  local total_work=${#TO_STOW[@]}
  if [[ $total_work -eq 0 ]]; then
    section "Complete"
    log_ok "All packages already stowed, nothing to do!"
    if [[ ${#ALREADY_LINKED[@]} -gt 0 ]]; then
      log_info "Added ${#ALREADY_LINKED[@]} package(s) to history"
    fi
    exit 0
  fi

  # Step 2: Unstow packages that have existing symlinks (before backup)
  if [[ ${#TO_UNSTOW_FIRST[@]} -gt 0 ]]; then
    section "Unstowing Existing Symlinks"
    for pkg in "${TO_UNSTOW_FIRST[@]}"; do
      log_info "Unstowing: $pkg"
      do_unstow "$pkg"
      log_ok "Unstowed: $pkg"
    done
  fi

  # Step 3: Backup configurations
  section "Backing Up Configurations"
  mkdir -p "$BACKUP_STAGING"

  for pkg in "${TO_STOW[@]}"; do
    backup_paths_for_package "$pkg"
  done

  create_backup_archive

  # Step 4: Remove backed up files
  section "Cleaning Up"
  remove_backed_up_files

  # Step 5: Stow packages
  section "Stowing Dotfiles"

  for pkg in "${TO_STOW[@]}"; do
    log_info "Stowing: $pkg"
    if do_stow "$pkg"; then
      log_ok "Stowed: $pkg"
    fi
  done

  # Summary
  section "Complete"
  log_ok "Successfully processed ${#TO_STOW[@]} package(s)"
  if [[ ${#ALREADY_LINKED[@]} -gt 0 ]]; then
    log_ok "Added ${#ALREADY_LINKED[@]} already-linked package(s) to history"
  fi
  log_info "History: $HISTORY_FILE"
  if [[ -f "$BACKUP_ARCHIVE" ]]; then
    log_info "Backup: $BACKUP_ARCHIVE"
    echo -e "\n${GRAY}To restore backup: ${NC}tar -xzf $BACKUP_ARCHIVE -C ~/\n" >&2
  fi
}

main "$@"
