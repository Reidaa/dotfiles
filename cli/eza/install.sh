#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

. "${repo_root}/.template/lib.sh"
. "${repo_root}/.template/install_package.sh"

install_package "eza"

if ! string_in_file "eza" "${HOME}/.zshrc"; then
	echo 'alias ls="eza"' >>"${HOME}/.zshrc"
else
	echo "eza already aliased in .zshrc"
fi
