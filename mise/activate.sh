shell=$(basename "$SHELL")

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

if command_exists "mise"; then
	eval "$(mise activate ${shell})"
fi
