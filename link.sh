#!/bin/bash

set -euo pipefail
set -x

# Function to check if a file exists
# Usage: file_exists /path/to/file
file_exists() {
	if [ -e "$1" ]; then
		echo "File exists: $1"
		return 0
	else
		echo "File does not exist: $1"
		return 1
	fi
}

mkdir -p "$HOME/.config"

confs=(
	"$(pwd)/starship/starship.toml,$HOME/.config/starship/starship.toml"
	"$(pwd)/tmux/tmux.conf,$HOME/.tmux.conf"
)

for conf in "${confs[@]}"; do
	IFS=',' read -r src dest <<<"$conf"
	mkdir -p "$(dirname "$dest")"
	rm -f "$dest"
	if [ -f "$src" ] && [ ! -e "$dest" ]; then
		ln -s "$src" "$dest"
	fi
done
