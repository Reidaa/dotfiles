#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

python3 "${repo_root}/.template/install_package.py" \
	--brew atuin \
	--script https://setup.atuin.sh

if ! grep -Fq -- "atuin" "${HOME}/.zshrc"; then
	cat >>"${HOME}/.zshrc" <<'EOF'

eval "$(atuin init zsh)"
EOF
else
	echo "atuin already sourced in .zshrc"
fi
