#!/usr/bin/env bash
# Installs the CLI tools in cli/brew/Brewfile with Homebrew, on Linux and macOS.
# Homebrew must already be installed; this script does not install it. If brew
# is missing, it reports it and exits 1.
# Safe to run again: `brew bundle` skips what is already installed.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Prints the path of brew, or nothing. brew is often not on PATH yet (only a
# new shell runs zsh/rc.zsh), so also look in Homebrew's default prefixes.
# HOMEBREW_PREFIX, when set, picks the prefix (install.sh and zsh/rc.zsh do
# the same).
find_brew() {
	local candidate
	if [ -n "${HOMEBREW_PREFIX:-}" ]; then
		candidate="${HOMEBREW_PREFIX}/bin/brew"
		if [ -x "$candidate" ]; then echo "$candidate"; fi
		return 0
	fi
	for candidate in "$(command -v brew || true)" /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
		if [ -n "$candidate" ] && [ -x "$candidate" ]; then
			echo "$candidate"
			return 0
		fi
	done
}

brew_bin="$(find_brew)"
if [ -z "$brew_bin" ]; then
	echo "Homebrew is not installed. Install it from https://brew.sh, then run this again." >&2
	exit 1
fi

"$brew_bin" bundle --file="${script_dir}/Brewfile"
