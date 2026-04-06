
if command -v try &> /dev/null; then
  eval "$(try init ~/Work/tries)"
fi

# Load atuin env if present
# if [[ -f "$HOME/.atuin/bin/env" ]]; then
#   source "$HOME/.atuin/bin/env"
# fi

# # Initialize atuin only if available
# if command -v atuin >/dev/null 2>&1; then
#   eval "$(atuin init zsh)"
# fi

# opencode
export PATH=/home/$USER/.opencode/bin:$PATH

# fnm
FNM_PATH="/home/$USER/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi
