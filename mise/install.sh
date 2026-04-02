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
	brew install mise
else
	if ! confirm "Install mise by downloading and running the installation script?"; then
		echo "Installation cancelled."
		exit
	fi
	curl https://mise.run | sh
fi


if ! string_in_file "mise" "${HOME}/.zshrc"; then
	echo 'eval "$(mise activate zsh)"' >>"${HOME}/.zshrc"
else
	echo "mise already sourced in .zshrc"
fi