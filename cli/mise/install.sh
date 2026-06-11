#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

. "${repo_root}/.template/lib.sh"
. "${repo_root}/.template/install_package.sh"

install_package "mise,script=https://mise.run"

if ! string_in_file "mise" "${HOME}/.zshrc"; then
	echo 'eval "$(mise activate zsh)"' >>"${HOME}/.zshrc"
else
	echo "mise already sourced in .zshrc"
fi
