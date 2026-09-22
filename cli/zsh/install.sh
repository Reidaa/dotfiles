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

brew_prefix=""
if command -v brew >/dev/null 2>&1; then
	brew install zsh-autosuggestions zsh-syntax-highlighting
	brew_prefix="$(brew --prefix)"
	bash "$(dirname "${BASH_SOURCE[0]}")/cleanup-legacy.sh" "$brew_prefix"
else
	mkdir -p "$plugins_dir"
fi

touch "$zshrc"

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
	if [ -n "$brew_prefix" ]; then
		plugin_path="${brew_prefix}/share/${plugin}/${plugin}.zsh"
	else
		target="${plugins_dir}/${plugin}"
		[ -d "$target" ] || git clone "https://github.com/zsh-users/${plugin}" "$target"
		plugin_path="${target}/${plugin}.zsh"
	fi

	printf -v entry 'source %q' "$plugin_path"
	if ! grep -Fxq -- "$entry" "$zshrc"; then
		printf '\n%s\n' "$entry" >>"$zshrc"
	fi
done
