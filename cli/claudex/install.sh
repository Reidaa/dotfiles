#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

. "${repo_root}/.template/lib.sh"

python3 "${repo_root}/.template/install_package.py" \
	--brew cliproxyapi \
	--command cliproxyapi \
	--command CLIProxyAPI

config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/claudex"
config_file="${config_dir}/config.zsh"
zshrc="${HOME}/.zshrc"
activation_line="source ${script_dir}/activate.sh"

mkdir -p "$config_dir"
chmod 700 "$config_dir"

if [[ ! -e $config_file ]]; then
	cp "${script_dir}/config.example.zsh" "$config_file"
	chmod 600 "$config_file"
	echo "Created $config_file"
else
	echo "Preserving existing $config_file"
fi

touch "$zshrc"

if ! string_in_file "$activation_line" "$zshrc"; then
	printf '\n%s\n' "$activation_line" >>"$zshrc"
	echo "Added Claudex activation to $zshrc"
else
	echo "Claudex already sourced in $zshrc"
fi

echo
echo "Claudex is installed and ready to configure."
echo "Follow ${script_dir}/README.md, then reload your shell with:"
echo "  source $zshrc"
