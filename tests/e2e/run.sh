#!/usr/bin/env bash
# End-to-end test of the `curl | bash` bootstrap in a clean container.
#
#   tests/e2e/run.sh IMAGE      for example: tests/e2e/run.sh fedora:45
#   tests/e2e/run.sh macos      on a GitHub macOS runner only (see check.sh)
#
# Runs on the host. It snapshots the committed HEAD of this repo as a bare git
# repo, then starts IMAGE with podman (or docker) and runs check.sh inside.
# macOS has no container image, so `macos` runs check.sh on the host itself.
# Uncommitted changes are not tested: install.sh clones, so it only sees commits.
#
# Env: CONTAINER_ENGINE (podman or docker; default: podman if installed).

set -euo pipefail

image="${1:?usage: $0 IMAGE}"
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${here}/../.." && pwd)"

engine="${CONTAINER_ENGINE:-}"
if [ -z "$engine" ]; then
	if command -v podman >/dev/null 2>&1; then engine=podman; else engine=docker; fi
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Bare snapshot with HEAD on branch main, so `git pull` works on the rerun.
# `clone --bare` (not push) also works from the shallow clone that CI checks out.
git clone -q --bare "$repo_root" "${tmp}/dotfiles.git"
git -C "${tmp}/dotfiles.git" update-ref refs/heads/main "$(git -C "$repo_root" rev-parse HEAD)"
git -C "${tmp}/dotfiles.git" symbolic-ref HEAD refs/heads/main
cp "${here}/check.sh" "${tmp}/check.sh"

if [ "$image" = macos ]; then
	if [ "$(uname -s)" != Darwin ]; then
		echo "macos runs check.sh on this host, and this host is not macOS" >&2
		exit 2
	fi
	echo "e2e: macOS on this host, commit $(git -C "$repo_root" rev-parse --short HEAD)"
	E2E_DIR="$tmp" bash "${tmp}/check.sh"
	exit 0
fi

echo "e2e: ${image} with ${engine}, commit $(git -C "$repo_root" rev-parse --short HEAD)"

# No -t and no -i: the container has no terminal and stdin is empty, like CI.
# The z flag relabels the temporary mount for SELinux hosts (Fedora).
"$engine" run --rm \
	--volume "${tmp}:/mnt/e2e:ro,z" \
	"$image" bash /mnt/e2e/check.sh
