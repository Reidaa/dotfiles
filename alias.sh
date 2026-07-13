# shellcheck shell=bash

# alias ls="ls -aF"
# alias ll="ls -l"
# alias make="make -j$(nproc)"

alias grep="grep --color=auto"
alias ls="eza"
alias ll="ls -l"
alias la="ls -la"

if command -v nvim &>/dev/null; then
  alias vim="nvim"
  alias vi="nvim"
fi

if command -v copilot &>/dev/null; then
	alias copilot="copilot --yolo"
fi

alias zshrc='$EDITOR ~/.zshrc'

if command -v claude &>/dev/null; then
	alias claude="claude --dangerously-skip-permissions"
fi

if command -v codex &>/dev/null; then
	alias codex="codex --yolo"
fi

if command -v opencode &>/dev/null; then
	alias opencode="opencode --auto"
fi
