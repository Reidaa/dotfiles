#!/usr/bin/env bash
# Sets up this machine from the repo. install.sh runs it; it is safe to run
# again at any time.
#
# 1. Adds one line to ~/.zshrc that sources zsh/rc.zsh (only once).
# 2. Runs cli/brew/install.sh first, so the other installers can use the
#    tools Homebrew installs. Then every other cli/*/install.sh, then my/install.sh.
# A failed installer does not stop the others. At the end, init.sh lists the
# failed installers and exits 1 if there are any.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
failed=()

source_rc() {
	local zshrc="${HOME}/.zshrc"
	local line="source \"${script_dir}/zsh/rc.zsh\""

	touch "$zshrc"

	if grep -Fxq -- "$line" "$zshrc"; then
		echo "zsh/rc.zsh already sourced in .zshrc"
		return
	fi

	# Start on a new line if the file does not end with one.
	if [ -s "$zshrc" ] && [ -n "$(tail -c 1 "$zshrc")" ]; then
		echo >>"$zshrc"
	fi
	echo "$line" >>"$zshrc"
}

run_installer() {
	local name="${1#"$script_dir"/}"

	echo "Running ${name}"
	if ! bash "$1"; then
		echo "${name} failed" >&2
		failed+=("$name")
	fi
}

source_rc

run_installer "${script_dir}/cli/brew/install.sh"

for installer in "${script_dir}"/cli/*/install.sh; do
	[ "$installer" = "${script_dir}/cli/brew/install.sh" ] && continue
	run_installer "$installer"
done

run_installer "${script_dir}/my/install.sh"

if [ "${#failed[@]}" -gt 0 ]; then
	echo >&2
	echo "${#failed[@]} installer(s) failed:" >&2
	printf '  %s\n' "${failed[@]}" >&2
	exit 1
fi

echo "All installers succeeded"
