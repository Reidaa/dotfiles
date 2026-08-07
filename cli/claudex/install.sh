#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_file="${script_dir}/config.zsh"
zshrc="${HOME}/.zshrc"
activation_line="source ${script_dir}/activate.sh"

if [[ ! -e $config_file ]]; then
	cp "${script_dir}/config.example.zsh" "$config_file"
	chmod 600 "$config_file"
	echo "Created $config_file"
else
	echo "Preserving existing $config_file"
fi

touch "$zshrc"

if ! grep -Fq -- "$activation_line" "$zshrc"; then
	printf '\n%s\n' "$activation_line" >>"$zshrc"
	echo "Added Claudex activation to $zshrc"
else
	echo "Claudex already sourced in $zshrc"
fi

echo
echo "Claudex is installed and ready to configure."
echo "Set your values in $config_file, then reload your shell with:"
echo "  source $zshrc"
