if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi

if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

if command -v try &>/dev/null; then
  eval "$(try init ~/Work/tries)"
fi

if command -v fzf &>/dev/null; then
  eval "$(fzf --bash)"
fi

# Load atuin env if present
if [[ -f "$HOME/.atuin/bin/env" ]]; then
  source "$HOME/.atuin/bin/env"
fi

# bash-preexec (required for atuin)
if [[ -f "$HOME/.bash-preexec.sh" ]]; then
  source "$HOME/.bash-preexec.sh"
fi

# Initialize atuin only if available
if command -v atuin &>/dev/null; then
  eval "$(atuin init bash)"
fi

# opencode
export PATH=/home/$USER/.opencode/bin:$PATH

# fnm
FNM_PATH="/home/$USER/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell bash)"
fi

# GPG signing support
if command -v gpg-connect-agent >/dev/null 2>&1; then
  export GPG_TTY=$(tty)
  gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
fi
