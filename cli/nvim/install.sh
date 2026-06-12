#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

. "${repo_root}/.template/lib.sh"

zshrc="${HOME}/.zshrc"

python3 "${repo_root}/.template/install_package.py" \
	--brew neovim \
	--apt neovim \
	--dnf neovim \
	--yum neovim \
	--pacman neovim \
	--apk neovim \
	--command nvim

touch "$zshrc"

if ! string_in_file 'alias vim="nvim"' "$zshrc"; then
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
