#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

. "${repo_root}/.template/lib.sh"
. "${repo_root}/.template/install_package.sh"

install_package \
	--brew starship \
	--script https://starship.rs/install.sh

if ! string_in_file "starship" "${HOME}/.zshrc"; then
	echo 'eval "$(starship init zsh)"' >>"${HOME}/.zshrc"
else
	echo "starship already sourced in .zshrc"
fi
