#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

python3 "${repo_root}/.template/install_package.py" --brew eza

if ! grep -Fq -- "eza" "${HOME}/.zshrc"; then
	echo 'alias ls="eza"' >>"${HOME}/.zshrc"
else
	echo "eza already aliased in .zshrc"
fi
