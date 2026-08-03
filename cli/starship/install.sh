#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

. "${repo_root}/.template/lib.sh"

python3 "${repo_root}/.template/install_package.py" \
	--brew starship \
	--script https://starship.rs/install.sh

if ! string_in_file "starship" "${HOME}/.zshrc"; then
	cat >>"${HOME}/.zshrc" <<'EOF'
eval "$(starship init zsh)"
EOF
else
	echo "starship already sourced in .zshrc"
fi

mkdir -p "$HOME/.config"

confs=(
	"${script_dir}/starship.toml,$HOME/.config/starship.toml"
)

for conf in "${confs[@]}"; do
	IFS=',' read -r src dest <<<"$conf"
	mkdir -p "$(dirname "$dest")"
	rm -f "$dest"
	if [ -f "$src" ] && [ ! -e "$dest" ]; then
		ln -s "$src" "$dest"
	fi
done
