#!/bin/bash

# Function to check if a file exists
# Usage: file_exists /path/to/file
file_exists() {
    if [ -a "$1" ]; then
        echo "File exists: $1"
        return 0
    else
        echo "File does not exist: $1"
        return 1
    fi
}

mkdir -p "$HOME/.config"

confs=(
    "$(pwd)/starship.toml,$HOME/.config/starship.toml"
    "$(pwd)/tmux.conf,$HOME/.config/tmux.conf"
)

for conf in "${confs[@]}"; do
    IFS=',' read -r src dest <<< "$conf"
    if [ ! "$(file_exists "$src")" ] && [ ! -a "$dest" ]; then
        ln -s "$src" "$dest"
    fi
done
