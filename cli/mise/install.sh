#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

python3 "${repo_root}/.template/install_package.py" \
	--brew mise \
	--script https://mise.run

if ! grep -Fq -- "mise" "${HOME}/.zshrc"; then
	cat >>"${HOME}/.zshrc" <<'EOF'

eval "$(mise activate zsh)"
EOF
else
	echo "mise already sourced in .zshrc"
fi
