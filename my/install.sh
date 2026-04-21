#!/usr/bin/env bash

script_path="${BASH_SOURCE[0]:-$0}"
script_dir=$(CDPATH= cd -- "$(dirname -- "$script_path")" && pwd)

mkdir -p "$HOME/.local/bin"
cp "$script_dir/artidl.py" "$HOME/.local/bin/artidl.py"
chmod +x "$HOME/.local/bin/artidl.py"
