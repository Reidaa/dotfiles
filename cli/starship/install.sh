#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

python3 "${repo_root}/.template/install_package.py" \
	--brew starship \
	--script https://starship.rs/install.sh

if ! grep -Fq -- "starship" "${HOME}/.zshrc"; then
	cat >>"${HOME}/.zshrc" <<'EOF'
eval "$(starship init zsh)"
EOF
else
	echo "starship already sourced in .zshrc"
fi

mkdir -p "$HOME/.config"
ln -sfn "${script_dir}/starship.toml" "$HOME/.config/starship.toml"
