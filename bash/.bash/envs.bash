# Editor used by CLI
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi

# zed
export PATH="$HOME/.local/bin:$PATH"

# language
export LANG=en_IN.UTF-8

# FZF theme (Catpuccin)
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

# # FZF theme - Everforest (dark)
# export FZF_DEFAULT_OPTS=" \
# --color=bg:#1E2326,bg+:#272E33,spinner:#D3C6AA,hl:#E67E80 \
# --color=fg:#D3C6AA,header:#E69875,info:#A7C080,pointer:#E6C384 \
# --color=marker:#83C092,fg+:#D3C6AA,prompt:#7FBBB3,hl+:#E67E80 \
# --color=selected-bg:#374145 \
# --color=border:#414B50,label:#9DA9A0"

# GPG TTY
export GPG_TTY=$(tty)

# DOCKER_HOST=unix:///run/user/1000/docker.sock
export PATH="$HOME/.bun/bin:$PATH"

# Use kitty's ssh kitten only when `-k` flag passed
ssh() {
  local use_kitty=0
  local args=()

  for arg in "$@"; do
    if [[ "$arg" == "-k" ]]; then
      use_kitty=1
    else
      args+=("$arg")
    fi
  done

  if (( use_kitty )); then
    command kitten ssh "${args[@]}"
  else
    command ssh "${args[@]}"
  fi
}

# mise shim
export PATH="$HOME/.local/share/mise/shims:$PATH"
