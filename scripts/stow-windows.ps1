# ==============================
# Manual Dotfiles Symlink Script
# PowerShell only
# ==============================

$ErrorActionPreference = "Stop"

$DOTFILES = "$HOME\dotfiles"

function Link-File {
  param (
    [Parameter(Mandatory)]
    [string]$Source,

    [Parameter(Mandatory)]
    [string]$Target
  )

  if (!(Test-Path $Source)) {
    Write-Warning "Source not found: $Source"
    return
  }

  # Ensure parent directory exists
  $parent = Split-Path $Target -Parent
  if ($parent -and !(Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  # Remove existing file or symlink
  if (Test-Path $Target) {
    Write-Host "Removing existing: $Target"
    Remove-Item $Target -Force
  }

  Write-Host "Linking $Target → $Source"
  New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
}

# ==============================
# Git
# ==============================
Link-File `
  -Source "$DOTFILES\git\.config/git/config" `
  -Target "$HOME\.gitconfig"

# ==============================
# Neovim
# ==============================
Link-File `
  -Source "$DOTFILES\nvim\.config\nvim" `
  -Target "$HOME\AppData\Local\nvim"

# ==============================
# Alacritty
# ==============================
Link-File `
  -Source "$DOTFILES\alacritty\.config\alacritty" `
  -Target "$HOME\AppData\Roaming\alacritty"

# ==============================
# Bat
# ==============================
Link-File `
  -Source "$DOTFILES\bat\.config\bat" `
  -Target "$HOME\AppData\Roaming\bat"

# ==============================
# btop
# ==============================
Link-File `
  -Source "$DOTFILES\btop\.config\btop" `
  -Target "$HOME\AppData\Roaming\btop"

# ==============================
# eza
# ==============================
Link-File `
  -Source "$DOTFILES\eza\.config\eza" `
  -Target "$HOME\AppData\Roaming\eza"

# ==============================
# eza
# ==============================
Link-File `
  -Source "$DOTFILES\fastfetch\.config\fastfetch" `
  -Target "$HOME\AppData\Roaming\fastfetch"

# ==============================
# starship
# ==============================
Link-File `
  -Source "$DOTFILES\starship\.config\starship.toml" `
  -Target "$HOME\.config/starship.toml"

# ==============================
# yazi
# ==============================
Link-File `
  -Source "$DOTFILES\yazi\.config\yazi" `
  -Target "$HOME\AppData\Roaming\yazi"

# ==============================
# zed
# ==============================
Link-File `
  -Source "$DOTFILES\zed\.config\zed" `
  -Target "$HOME\AppData\Roaming\zed"

# ==============================
# powershell
# ==============================
Link-File `
  -Source "$DOTFILES\pwsh\pwsh.ps1" `
  -Target "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

Write-Host "`n✔ Dotfiles linked successfully"
