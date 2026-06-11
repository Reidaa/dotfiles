#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

. "${repo_root}/.template/lib.sh"

if command -v brew >/dev/null 2>&1; then
	brew install atuin
	if ! string_in_file "atuin" "${HOME}/.zshrc"; then
		echo 'eval "$(atuin init zsh)"' >>"${HOME}/.zshrc"
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
