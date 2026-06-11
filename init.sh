#!/bin/bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

run_installer() {
	local installer="$1"

	echo "Running ${installer#"$script_dir"/}"
	bash "$installer"
}

run_installer "${script_dir}/zsh/autosuggestions/install.sh"
run_installer "${script_dir}/zsh/syntax-highlighting/install.sh"
run_installer "${script_dir}/starship/install.sh"

for installer in "${script_dir}"/cli/*/install.sh; do
	run_installer "$installer"
done
# . my/install.sh
