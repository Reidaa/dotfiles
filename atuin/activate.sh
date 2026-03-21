check_cmd() {
	command -v "$1" >/dev/null 2>&1
	return $?
}

need_cmd() {
	if ! check_cmd "$1"; then
		err "need '$1' (command not found)"
	fi
}

shell=$(basename "$SHELL")

need_cmd atuin

eval "$(atuin init ${shell})"
