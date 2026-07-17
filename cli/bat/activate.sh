# shellcheck shell=bash

### bat - https://github.com/fdellwing/zsh-bat/blob/master/zsh-bat.plugin.zsh
if command -v batcat >/dev/null 2>&1; then
	# Bypass the replacement `cat` alias.
	alias rcat='command cat'

	# For Ubuntu and Debian-based `bat` packages, the `bat` program is named `batcat`.
	alias cat='batcat'
	export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
	export MANROFFOPT="-c"
elif command -v bat >/dev/null 2>&1; then
	# Bypass the replacement `cat` alias.
	alias rcat='command cat'

	# For all other systems.
	alias cat='bat'
	export MANPAGER="sh -c 'col -bx | bat -l man -p'"
	export MANROFFOPT="-c"
fi
###
