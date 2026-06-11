#!/usr/bin/env bash

# Check whether a command is available in PATH.
# Usage: command_exists git
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Check whether a string exists in a file.
# Usage: string_in_file "needle" /path/to/file
string_in_file() {
	grep -Fq -- "$1" "$2"
}

confirm() {
	local prompt="${1:-Continue?}"
	local reply

	read -r -p "${prompt} [y/N] " reply
	case "$reply" in
	[yY] | [yY][eE][sS]) return 0 ;;
	*) return 1 ;;
	esac
}
