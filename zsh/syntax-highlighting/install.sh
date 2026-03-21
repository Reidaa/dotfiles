#!/usr/bin/env bash

confirm() {
	local prompt="${1:-Continue?}"
	local reply

	read -r -p "${prompt} [y/N] " reply
	case "$reply" in
	[yY] | [yY][eE][sS]) return 0 ;;
	*) return 1 ;;
	esac
}

# Check whether a string exists in a file.
# Usage: string_in_file "needle" /path/to/file
string_in_file() {
	grep -Fq -- "$1" "$2"
}

REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
ZSH_PLUGINS_INSTALL_DIR="${HOME}/.local/zsh/plugins"
INSTALL_DIR="${ZSH_PLUGINS_INSTALL_DIR}/zsh-syntax-highlighting"

if [ ! -d "${HOME}/.local/zsh/plugins" ]; then
	mkdir -p "${ZSH_PLUGINS_INSTALL_DIR}"
fi

if [ ! -d "${INSTALL_DIR}" ]; then
	git clone "${REPO}" "${INSTALL_DIR}"
fi

if string_in_file "zsh-syntax-highlighting.zsh" "${HOME}/.zshrc"; then
	echo "zsh-syntax-highlighting already sourced in .zshrc"
else
	echo "source ${HOME}/.local/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >>"${HOME}/.zshrc"
fi
