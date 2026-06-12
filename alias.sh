# shellcheck shell=bash

# alias ls="ls -aF"
# alias ll="ls -l"
# alias make="make -j$(nproc)"

alias grep="grep --color=auto"

if command -v copilot &>/dev/null; then
	alias copilot="copilot --yolo"
fi

alias zshrc='$EDITOR ~/.zshrc'
