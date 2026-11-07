#!/usr/bin/env bash
# Clones the zsh plugins. zsh/rc.zsh sources them.

set -euo pipefail

# These plugins only work in zsh, so skip the install on other login shells.
case "${SHELL:-}" in
*/zsh) ;;
*)
	echo "login shell is not zsh (SHELL=${SHELL:-unset}), skipping" >&2
	exit 0
	;;
esac

plugins_dir="${HOME}/.local/zsh/plugins"

mkdir -p "$plugins_dir"

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
	target="${plugins_dir}/${plugin}"
	[ -d "$target" ] || git clone "https://github.com/zsh-users/${plugin}" "$target"
done
