#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

. "${repo_root}/.template/lib.sh"

if command_exists starship; then
	echo "starship already installed"
elif command_exists brew; then
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
