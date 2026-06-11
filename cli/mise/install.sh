#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

. "${repo_root}/.template/lib.sh"

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
