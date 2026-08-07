#!/usr/bin/env bash

set -euo pipefail

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
