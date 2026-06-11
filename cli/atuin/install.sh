#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

. "${repo_root}/.template/lib.sh"

if command_exists atuin; then
	echo "atuin already installed"
elif command_exists brew; then
	brew install atuin
else
	if ! confirm "Install atuin by downloading and running the installation script?"; then
		echo "Installation cancelled."
		exit
	fi
	curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

if ! string_in_file "atuin" "${HOME}/.zshrc"; then
	echo 'eval "$(atuin init zsh)"' >>"${HOME}/.zshrc"
else
	echo "atuin already sourced in .zshrc"
fi
