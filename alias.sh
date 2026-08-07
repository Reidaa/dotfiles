# shellcheck shell=bash

alias grep="grep --color=auto"
alias ls="eza"
alias ll="ls -l"
alias la="ls -la"
alias zsh-edit='$EDITOR ~/.zshrc'
alias zsh-source="source ~/.zshrc"
alias ssh-edit='$EDITOR ~/.ssh/config'

if command -v nvim &>/dev/null; then
	alias vim="nvim"
	alias vi="nvim"
fi

if command -v copilot &>/dev/null; then
	alias copilot="copilot --yolo"
fi

if command -v claude &>/dev/null; then
	alias claude="claude --dangerously-skip-permissions"
fi

if command -v codex &>/dev/null; then
	alias codex="codex --yolo"
fi

if command -v code &>/dev/null; then
	alias dotfiles-edit='code "$HOME/.dotfiles"'
fi
