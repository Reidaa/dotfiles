#!/usr/bin/env bash
# Bootstrap for a new machine:
#   curl -fsSL https://raw.githubusercontent.com/Reidaa/dotfiles/main/install.sh | bash
#
# Clones the repo to $DOTFILES_DIR (default ~/.dotfiles), or fast-forwards an
# existing clone, then runs init.sh from it. The clone must stay on disk:
# .zshrc sources files from it.
#
# Needs git and Homebrew. It does not install Homebrew: if brew is missing, it
# reports it and exits before it changes anything.
#
# Overrides: DOTFILES_DIR (clone location), DOTFILES_REPO (clone source).

# True if Homebrew is installed. brew is often not on PATH yet, so also look
# in Homebrew's default prefixes. HOMEBREW_PREFIX, when set, picks the prefix
# (cli/brew/install.sh and zsh/rc.zsh use the same lookup).
has_brew() {
	if [ -n "${HOMEBREW_PREFIX:-}" ]; then
		[ -x "${HOMEBREW_PREFIX}/bin/brew" ]
		return
	fi
	command -v brew >/dev/null 2>&1 ||
		[ -x /opt/homebrew/bin/brew ] ||
		[ -x /usr/local/bin/brew ] ||
		[ -x /home/linuxbrew/.linuxbrew/bin/brew ]
}

# Everything runs inside main, called on the last line. If the download
# stops halfway, bash never runs a partial script.
main() {
	set -euo pipefail

	local repo="${DOTFILES_REPO:-https://github.com/Reidaa/dotfiles.git}"
	local dir="${DOTFILES_DIR:-${HOME}/.dotfiles}"

	if ! command -v git >/dev/null 2>&1; then
		echo "git is required but was not found in PATH" >&2
		exit 1
	fi

	if ! has_brew; then
		echo "Homebrew is required but was not found. Install it from https://brew.sh, then run this installer again." >&2
		exit 1
	fi

	if [ -d "${dir}/.git" ]; then
		echo "Updating ${dir}"
		git -C "$dir" pull --ff-only
	elif [ -e "$dir" ]; then
		echo "${dir} exists and is not a git clone; move it or set DOTFILES_DIR" >&2
		exit 1
	else
		echo "Cloning ${repo} to ${dir}"
		git clone "$repo" "$dir"
	fi

	bash "${dir}/init.sh"
}

main "$@"
