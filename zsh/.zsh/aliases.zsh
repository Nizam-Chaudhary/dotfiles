alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

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

if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
  export VISUAL="vim"
else
  export EDITOR="vi"
  export VISUAL="vi"
fi

alias ag='antigravity'
