#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

. "${repo_root}/.template/lib.sh"

python3 "${repo_root}/.template/install_package.py" \
	--brew atuin \
	--script https://setup.atuin.sh

if ! string_in_file "atuin" "${HOME}/.zshrc"; then
	echo 'eval "$(atuin init zsh)"' >>"${HOME}/.zshrc"
else
	echo "atuin already sourced in .zshrc"
fi
