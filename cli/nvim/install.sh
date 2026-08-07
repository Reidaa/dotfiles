#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

zshrc="${HOME}/.zshrc"

python3 "${repo_root}/.template/install_package.py" \
	--brew neovim \
	--apt neovim \
	--dnf neovim \
	--pacman neovim \
	--apk neovim \
	--command nvim

touch "$zshrc"

if ! grep -Fq -- 'alias vim="nvim"' "$zshrc"; then
	cat >>"$zshrc" <<'EOF'

if command -v nvim &>/dev/null; then
	export EDITOR="nvim"
	alias vim="nvim"
	alias vi="nvim"
fi
EOF
else
	echo "nvim aliases already configured in .zshrc"
fi
