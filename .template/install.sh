#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

. "${script_dir}/lib.sh"

# if command -v brew >/dev/null 2>&1; then
# 	brew install starship
# 	if ! string_in_file "starship" "${HOME}/.zshrc"; then
# 		echo 'eval "$(starship init zsh)"' >>"${HOME}/.zshrc"
# 	else
# 		echo "starship already sourced in .zshrc"
# 	fi
# else
# 	if ! confirm "Install starship by downloading and running the installation script?"; then
# 		echo "Installation cancelled."
# 		exit
# 	fi
# 	curl -sS https://starship.rs/install.sh | sh
# fi
