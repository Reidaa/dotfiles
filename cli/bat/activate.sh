# shellcheck shell=bash

# Sourced from zsh/rc.zsh.

### bat - https://github.com/fdellwing/zsh-bat/blob/master/zsh-bat.plugin.zsh
if command -v bat >/dev/null 2>&1; then
	# Bypass the replacement `cat` alias.
	alias rcat='command cat'

	alias cat='bat'
	export MANPAGER="sh -c 'col -bx | bat -l man -p'"
	export MANROFFOPT="-c"
fi
###
