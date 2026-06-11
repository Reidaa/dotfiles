#!/bin/bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source_aliases() {
	local zshrc="${HOME}/.zshrc"
	local aliases_file="${script_dir}/alias.sh"

	touch "$zshrc"

	if grep -Fq "$aliases_file" "$zshrc"; then
		echo "aliases already sourced in .zshrc"
	else
		echo "source ${aliases_file}" >>"$zshrc"
	fi
}

run_installer() {
	local installer="$1"

	echo "Running ${installer#"$script_dir"/}"
	bash "$installer"
}

source_aliases

run_installer "${script_dir}/zsh/autosuggestions/install.sh"
run_installer "${script_dir}/zsh/syntax-highlighting/install.sh"
run_installer "${script_dir}/starship/install.sh"

for installer in "${script_dir}"/cli/*/install.sh; do
	run_installer "$installer"
done
# . my/install.sh
