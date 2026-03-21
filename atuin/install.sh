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
	brew install atuin
	if ! string_in_file "atuin" "${HOME}/.zshrc"; then
		echo "source $(pwd)/activate.sh" >>"${HOME}/.zshrc"
	else
		echo "atuin already sourced in .zshrc"
	fi
else
	if ! confirm "Install atuin by downloading and running the installation script?"; then
		echo "Installation cancelled."
		exit
	fi
	curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi
