#!/usr/bin/env bash

set -euo pipefail

script_path="${BASH_SOURCE[0]:-$0}"
script_dir=$(CDPATH='' cd -- "$(dirname -- "$script_path")" && pwd)

mkdir -p "$HOME/.local/bin"

install_script() {
	local source="$1"
	local target="$2"

	cp "$script_dir/$source" "$HOME/.local/bin/$target"
	chmod +x "$HOME/.local/bin/$target"
}

install_script "artidl.py" "artidl.py"
install_script "commit-message.sh" "commit-message"
