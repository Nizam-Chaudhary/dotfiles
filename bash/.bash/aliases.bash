# File system
if command -v eza &>/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

if command -v zoxide &>/dev/null; then
  alias cd="zd"
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && return
    elif [ -d "$1" ]; then
      builtin cd "$1"
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
fi

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

open() {
  xdg-open "$@" >/dev/null 2>&1 &
}

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Editors
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="vim"
  export VISUAL="vim"
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
  export VISUAL="vim"
else
  export EDITOR="vi"
  export VISUAL="vi"
fi

if command -v bat >/dev/null 2>&1; then
  alias cat="bat --no-pager --plain"
fi

alias vi=vim

# Tools
alias c='opencode'
alias d='docker'
alias r='rails'
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

# Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
