#!/usr/bin/env bash
# Bootstrap for a new machine:
#   curl -fsSL https://raw.githubusercontent.com/Reidaa/dotfiles/main/install.sh | bash
#
# Clones the repo to $DOTFILES_DIR (default ~/.dotfiles), or fast-forwards an
# existing clone, then runs init.sh from it. The clone must stay on disk:
# .zshrc sources files from it.
#
# Overrides: DOTFILES_DIR (clone location), DOTFILES_REPO (clone source).

# Everything is inside main, which runs on the last line. If the download
# stops halfway, bash never runs a partial script.
main() {
	set -euo pipefail

	local repo="${DOTFILES_REPO:-https://github.com/Reidaa/dotfiles.git}"
	local dir="${DOTFILES_DIR:-${HOME}/.dotfiles}"

	if ! command -v git >/dev/null 2>&1; then
		echo "git is required but was not found in PATH" >&2
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

	# Under `curl | bash`, stdin is the pipe, so installer prompts would read
	# EOF and cancel. Give init.sh the terminal when there is one (rustup does
	# the same); without a terminal (CI), prompts keep their default answer.
	if (exec </dev/tty) 2>/dev/null; then
		bash "${dir}/init.sh" </dev/tty
	else
		bash "${dir}/init.sh"
	fi
}

main "$@"
