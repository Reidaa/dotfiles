#!/usr/bin/env bash
# Started by tests/e2e/run.sh. Two modes:
#   - Linux: runs as root inside a clean container. Sets up a fresh machine
#     (git, curl, zsh, Homebrew's required packages, a non-root user `dev`
#     with zsh as login shell and passwordless sudo, like an admin user).
#     Homebrew is not installed, so this mode tests the Homebrew install too.
#   - macOS: runs on a GitHub macOS runner, not in a container. Uses the runner
#     user with a new empty HOME and the PATH of a new Mac, so preinstalled
#     tools do not count. Homebrew is preinstalled there, so this mode does
#     not test the Homebrew install itself.
# Then it pipes install.sh into bash twice, like `curl ... | bash`.
# DOTFILES_REPO points at the snapshot in $E2E_DIR (default /mnt/e2e).
#
# Checks (C2, C3, C5, C6 of the bootstrap contract):
#   - both runs exit 0, with no terminal;
#   - run 1 keeps ~/.zshrc and appends one line that sources zsh/rc.zsh
#     (Fedora's /etc/skel ships a .zshrc, so the file may exist before);
#   - run 2 leaves ~/.zshrc unchanged;
#   - a new `zsh -i` finds every tool in TOOLS as a file on PATH.
# It reports every failed check, then exits 1 if there was any.
# Keep it bash 3.2 compatible: that is the bash of macOS.

set -euo pipefail

# Commands the bootstrap must provide (C6), from cli/brew/Brewfile.
TOOLS=(atuin bat btop codex dua eza just mise nvim rg starship tldr tv)

src="${E2E_DIR:-/mnt/e2e}"

setup_linux() {
	# This mode adds a user and packages, so it must only run in a container
	# (podman makes /run/.containerenv, docker makes /.dockerenv).
	if [ ! -e /run/.containerenv ] && [ ! -e /.dockerenv ]; then
		echo "Linux mode changes the system; it runs only in a container" >&2
		exit 2
	fi
	# Base packages: what a fresh machine needs to run `curl ... | bash`
	# (git, curl, zsh), what Homebrew needs (sudo, ps from procps, file; see
	# https://docs.brew.sh/Homebrew-on-Linux#requirements, minus the compilers:
	# every tool has a prebuilt bottle), and what this script uses: runuser
	# (util-linux), cmp and diff (diffutils). Minimal images lack some of these.
	# shellcheck source=/dev/null
	. /etc/os-release
	os_name="$PRETTY_NAME"
	echo "::group::base packages"
	case "$ID" in
	ubuntu | debian)
		apt-get update -qq
		DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git curl zsh ca-certificates sudo procps file >/dev/null
		;;
	fedora) dnf install -y -q git-core curl zsh util-linux diffutils sudo procps-ng file >/dev/null ;;
	arch) pacman -Syu --noconfirm --needed --quiet git curl zsh diffutils sudo procps-ng file >/dev/null ;;
	*)
		echo "unsupported distro: $ID" >&2
		exit 2
		;;
	esac
	echo "::endgroup::"

	useradd --create-home --shell "$(command -v zsh)" dev
	home=/home/dev
	user=dev
	# Homebrew's installer runs sudo to create /home/linuxbrew. With no
	# terminal it cannot ask for a password, so allow sudo without one.
	echo 'dev ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/dev
	chmod 0440 /etc/sudoers.d/dev

	# The mount is read-only and owned by another user; git refuses to clone a
	# repo that `dev` does not own, so give dev its own copy.
	repo=/srv/dotfiles.git
	cp -r "${src}/dotfiles.git" "$repo"
	chown -R dev: "$repo"

	shell="$(command -v zsh)"
	lang=C.UTF-8
	path=/usr/local/bin:/usr/bin:/bin
}

setup_macos() {
	# This mode installs Homebrew packages on the host, so it must not run on
	# a developer's own Mac. GitHub Actions sets CI=true.
	if [ "${CI:-}" != true ]; then
		echo "macOS mode changes this Mac (brew packages); it runs only in CI" >&2
		exit 2
	fi
	os_name="macOS $(sw_vers -productVersion)"

	local root
	root="$(mktemp -d)"
	home="${root}/home"
	mkdir "$home"
	user="$(id -un)"
	repo="${root}/dotfiles.git"
	cp -R "${src}/dotfiles.git" "$repo"

	shell=/bin/zsh
	lang=en_US.UTF-8
	# A new Mac's PATH (/etc/paths) without /usr/local/bin, where the runner
	# keeps preinstalled tools.
	path=/usr/bin:/bin:/usr/sbin:/sbin
}

case "$(uname -s)" in
Linux) setup_linux ;;
Darwin) setup_macos ;;
*)
	echo "unsupported system: $(uname -s)" >&2
	exit 2
	;;
esac

# A clean login environment for the test user. stdin is never a terminal here.
user_env=(
	HOME="$home" USER="$user" LOGNAME="$user" SHELL="$shell" LANG="$lang"
	PATH="$path"
	DOTFILES_REPO="$repo"
)

# Runs a command as the test user, in a clean environment.
as_dev() {
	if [ "$(id -un)" = "$user" ]; then
		(cd "$home" && env -i "${user_env[@]}" "$@")
	else
		(cd "$home" && runuser -u "$user" -- env -i "${user_env[@]}" "$@")
	fi
}

failures=()
fail() {
	echo "FAIL: $*" >&2
	failures+=("$*")
}

# On Linux, root reads the file from dev's repo; -c allows that one call.
install_sh="$(git -c safe.directory='*' -C "$repo" show HEAD:install.sh)"

run_install() {
	echo "::group::install.sh run $1"
	local status=0
	printf '%s\n' "$install_sh" | as_dev bash || status=$?
	echo "::endgroup::"
	[ "$status" -eq 0 ] || fail "install.sh run $1 exited ${status}"
}

zshrc="${home}/.zshrc"
cat "$zshrc" >/tmp/zshrc.before 2>/dev/null || : >/tmp/zshrc.before

run_install 1

# C2: init.sh keeps what was there and appends only one `source .../zsh/rc.zsh` line.
# $(( )) strips the spaces that BSD wc (macOS) puts before the number.
before_size="$(($(wc -c </tmp/zshrc.before)))"
added="$(tail -c +"$((before_size + 1))" "$zshrc" 2>/dev/null || true)"
if ! head -c "$before_size" "$zshrc" 2>/dev/null | cmp -s - /tmp/zshrc.before ||
	[ "$(grep -c . <<<"$added")" != 1 ] || ! grep -q 'zsh/rc.zsh' <<<"$added"; then
	fail "run 1 must append only one line that sources zsh/rc.zsh to .zshrc; diff:"
	diff /tmp/zshrc.before "$zshrc" >&2 || true
fi

# C6: each tool is on PATH in a new interactive zsh. `whence -p` is
# `command -v` limited to PATH: an alias such as codex='codex --yolo' or the
# mise shell function would hide a missing binary.
for tool in "${TOOLS[@]}"; do
	if path="$(as_dev zsh -i -c "whence -p ${tool}" 2>/dev/null)"; then
		echo "found ${tool}: ${path}"
	else
		fail "zsh -i -c 'whence -p ${tool}' found no ${tool} on PATH"
	fi
done

# Idempotence: a second run succeeds and does not grow ~/.zshrc.
cp "$zshrc" /tmp/zshrc.run1 2>/dev/null || : >/tmp/zshrc.run1
run_install 2
if ! cmp -s /tmp/zshrc.run1 "$zshrc"; then
	fail "run 2 changed .zshrc:"
	diff /tmp/zshrc.run1 "$zshrc" >&2 || true
fi

if [ "${#failures[@]}" -gt 0 ]; then
	echo
	echo "${#failures[@]} check(s) failed on ${os_name}:" >&2
	printf '  - %s\n' "${failures[@]}" >&2
	exit 1
fi
echo "all checks passed on ${os_name}"
