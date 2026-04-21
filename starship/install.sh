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

if command -v brew >/dev/null 2>&1; then
	brew install starship
else
	if ! confirm "Install starship by downloading and running the installation script?"; then
		echo "Installation cancelled."
		exit
	fi
	curl -sS https://starship.rs/install.sh | sh
fi

if ! string_in_file "starship" "${HOME}/.zshrc"; then
	echo 'eval "$(starship init zsh)"' >>"${HOME}/.zshrc"
else
	echo "starship already sourced in .zshrc"
fi
