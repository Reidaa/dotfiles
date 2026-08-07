if ! command -v pi >/dev/null 2>&1; then
	echo "pi is required but was not found in PATH" >&2
	exit 1
fi

pi install npm:pi-autoresearch
pi install npm:pi-subagents
pi install https://github.com/Reidaa/pi-cliproxyapi.git
