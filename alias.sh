# shellcheck shell=bash
# Sourced by zsh/rc.zsh. Aliases for missing tools are skipped.

alias grep="grep --color=auto"
alias ll="ls -l"
alias la="ls -la"
alias zsh-edit='$EDITOR ~/.zshrc'
alias zsh-source="source ~/.zshrc"
alias ssh-edit='$EDITOR ~/.ssh/config'

if command -v eza &>/dev/null; then
	alias ls="eza"
fi

if command -v nvim &>/dev/null; then
	alias vim="nvim"
	alias vi="nvim"
fi

if command -v claude &>/dev/null; then
	alias claude="claude --dangerously-skip-permissions"
fi

if command -v codex &>/dev/null; then
	alias codex="codex --yolo"
fi

if command -v code &>/dev/null; then
	# dotfiles_dir is set by zsh/rc.zsh.
	# shellcheck disable=SC2154
	alias dotfiles-edit='code "$dotfiles_dir"'
fi
