# Windows Setup & Dotfiles Guide (winget + WSL + PowerShell)

This document describes a **clean, repeatable way** to set up a Windows machine using **winget**, **WSL**, and your existing **dotfiles** repository.

The steps are ordered so that **system-level changes come first**, followed by **developer tooling**, then **shell configuration**.

---

## 0. Prerequisites

- Windows 11 (or Windows 10 22H2+)
- Administrator access
- Stable internet connection

Open **Windows Terminal (Admin)** or **PowerShell (Admin)** for the system steps.

---

## 1. Update Windows & Microsoft Store Apps

### 1.1 Windows Update

- Open **Settings → Windows Update**
- Click **Check for updates**
- Install all available updates
- Enable sudo
- Reboot if required

Repeat until no updates remain.

### 1.2 Update Microsoft Store Apps

```powershell
winget upgrade --source msstore --all
```

---

## 2. Install Drivers

1. Run **Windows Update** again (many drivers come via WU)
2. Install OEM tools if required:
   - Intel Driver & Support Assistant
   - AMD Adrenalin
   - NVIDIA GeForce Experience
   - Laptop vendor utilities (Dell / Lenovo / HP / Acer)

Reboot after driver installation.

---

## 3. Core Browsers & Accounts

### 3.1 Install Google Chrome

```powershell
winget install -e --id Google.Chrome
```

### 3.2 Google Account Setup

- Open Chrome
- Sign in with Google account
- Enable sync (bookmarks, passwords, extensions)

---

## 4. Enable & Set Up WSL

### 4.1 Enable WSL Features

```powershell
wsl --install
```

This enables:

- Windows Subsystem for Linux
- Virtual Machine Platform

Reboot when prompted.

### 4.2 Install Ubuntu

```powershell
wsl --install -d Ubuntu
```

On first launch:

- Create Linux username
- Set password

### 4.3 Update Ubuntu

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 5. Update PowerShell to Latest

```powershell
winget install -e --id Microsoft.PowerShell
```

Verify:

```powershell
pwsh --version
```

Set **PowerShell 7** as default in Windows Terminal.

---

## 6. Install Desktop Applications

### 6.1 Developer & Utilities

```powershell
winget install -e --id Microsoft.VisualStudioCode
# winget install -e --id CursorAI.Cursor from website
winget install -e --id Zed.Zed
winget install -e --id Microsoft.PowerToys
```

### 6.2 Media & Productivity

```powershell
winget install -e --id SumatraPDF.SumatraPDF
winget install -e --id OBSProject.OBSStudio
winget install -e --id VideoLAN.VLC
winget install -e --id qBittorrent.qBittorrent
winget install -e --id ONLYOFFICE.DesktopEditors
```

### 6.3 Communication & Social

```powershell
winget install -e --id Obsidian.Obsidian
winget install -e --id Mozilla.Thunderbird
winget install -e --id Valve.Steam
winget install -e --id Discord.Discord
winget install -e --id WhatsApp.WhatsApp
winget install -e --id Microsoft.Teams
```

---

## 7. Git & GitHub Setup

### 7.1 Install Git

```powershell
winget install -e --id Git.Git
```

---

## 8. SSH Keys & Agent

### 8.1 Generate SSH Key

```powershell
ssh-keygen -t ed25519 -C "you@example.com"
```

### 8.2 Start SSH Agent

```powershell
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

Add the public key to GitHub.

---

## 9. GPG Keys

### 9.1 Install GnuPG

```powershell
winget install -e --id GnuPG.GnuPG
```

### 9.2 Generate Key

```powershell
gpg --full-generate-key
```

Export public key and add to GitHub.

---

## 10. PowerShell CLI Tools

Install core Unix-like tooling:

```powershell
winget install -e --id sharkdp.fd
winget install -e --id BurntSushi.ripgrep.MSVC
winget install -e --id eza-community.eza
winget install -e --id sharkdp.bat
winget install -e --id dandavison.delta        # git-delta
winget install -e --id sharkdp.dust
winget install -e --id Starship.Starship
winget install -e --id ajeetdsouza.zoxide
winget install -e --id junegunn.fzf

winget install tldr-pages.tlrc

winget install sxyazi.yazi
winget install Gyan.FFmpeg 7zip.7zip jqlang.jq oschwartz10612.Poppler sharkdp.fd BurntSushi.ripgrep.MSVC junegunn.fzf ajeetdsouza.zoxide ImageMagick.ImageMagick
```

Install powershell modules:

```powershell
Install-Module PSReadLine -Force
Install-Module CompletionPredictor
Install-Module posh-git
Install-Module TabExpansionPlusPlus
Install-Module PSFzf
```

---

## 11. Dotfiles Strategy (Windows)

### 11.1 Repository Structure (Current)

Make npm globals install available

```powershell
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($UserPath -notlike "*$env:LOCALAPPDATA\mise\shims*") {
  [Environment]::SetEnvironmentVariable(
    "Path",
    "$UserPath;$env:LOCALAPPDATA\mise\shims",
    "User"
  )
}
```

Your dotfiles are **Unix-first**, with clear separation:

- `bash/`, `zsh/` → Linux shells
- `pwsh/` → PowerShell config
- `.config/*` → app configs (nvim, git, bat, starship, etc.)

### 11.2 Stow Alternatives on Windows

Run script to stow the config files for windows

```powershell
./scripts/stow-windows.ps1
```

---

## 12. WSL + Dotfiles (Primary Setup)

### 12.1 Clone Dotfiles in WSL

```bash
git clone git@github.com:yourname/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 12.2 Run Bootstrap

```bash
./bootstrap.sh
# or
./scripts/setup-ubuntu-wsl.sh
```

This configures:

- bash / zsh
- nvim
- tmux
- git
- cli tools

---

## 13. PowerShell Configuration

### 13.1 PowerShell Dotfiles

Use:

```
pwsh/pwsh.ps1
```

Linked to:

```
$PROFILE
```

Features:

- eza-based ls
- fzf integration
- zoxide
- yazi cwd sync
- git helpers
- starship prompt

---

## 14. Final Checklist

- [ ] Windows fully updated
- [ ] Drivers installed
- [ ] WSL Ubuntu working
- [ ] PowerShell 7 default
- [ ] Git + SSH + GPG configured
- [ ] CLI tools installed
- [ ] Dotfiles applied (WSL + PowerShell)

---

## Notes

- Prefer **WSL for Linux workflows**
- Prefer **PowerShell for Windows-native tooling**
- Keep dotfiles **source of truth** in Git

---

This setup mirrors your Linux environment while staying native on Windows.
