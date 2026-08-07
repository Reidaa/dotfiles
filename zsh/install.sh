#!/usr/bin/env bash

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
zshrc="${HOME}/.zshrc"

mkdir -p "$plugins_dir"
touch "$zshrc"

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
	target="${plugins_dir}/${plugin}"
	[ -d "$target" ] || git clone "https://github.com/zsh-users/${plugin}" "$target"

	entry="source ${target}/${plugin}.zsh"
	if grep -Fq "$entry" "$zshrc"; then
		echo "${plugin} already sourced in .zshrc"
	else
		echo "$entry" >>"$zshrc"
	fi
done
