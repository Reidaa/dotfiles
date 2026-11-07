#!/usr/bin/env bash
# Creates the claudex config from the example. zsh/rc.zsh sources activate.zsh.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_file="${script_dir}/config.zsh"

if [[ ! -e $config_file ]]; then
	cp "${script_dir}/config.example.zsh" "$config_file"
	chmod 600 "$config_file"
	echo "Created $config_file"
else
	echo "Preserving existing $config_file"
fi

echo
echo "Claudex is installed and ready to configure."
echo "Set your values in $config_file, then open a new shell."
