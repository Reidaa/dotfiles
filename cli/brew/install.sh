#!/usr/bin/env bash
# Installs the CLI tools in cli/brew/Brewfile with Homebrew, on Linux and macOS.
# If Homebrew is missing, runs Homebrew's official installer. It needs sudo:
# with a terminal it asks for your password (init.sh gives it the terminal);
# with no terminal it runs non-interactively and needs passwordless sudo.
# Safe to run again: `brew bundle` skips what is already installed.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Homebrew's default prefix for this system. HOMEBREW_PREFIX overrides it.
prefix="${HOMEBREW_PREFIX:-}"
if [ -z "$prefix" ]; then
	case "$(uname -s)/$(uname -m)" in
	Darwin/arm64) prefix=/opt/homebrew ;;
	Darwin/*) prefix=/usr/local ;;
	*) prefix=/home/linuxbrew/.linuxbrew ;;
	esac
fi

# brew is often not on PATH yet: the Homebrew installer does not change PATH,
# and zsh/rc.zsh only adds it in a new shell.
brew_bin="$(command -v brew || echo "${prefix}/bin/brew")"
if [ ! -x "$brew_bin" ]; then
	echo "Installing Homebrew to ${prefix}"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [ ! -x "$brew_bin" ]; then
	echo "Homebrew install failed: ${brew_bin} not found" >&2
	exit 1
fi

"$brew_bin" bundle --file="${script_dir}/Brewfile"
