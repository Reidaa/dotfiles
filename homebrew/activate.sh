shell=$(basename "$SHELL")

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

if command_exists "brew"; then
	eval "$(starship init ${shell})"
fi
