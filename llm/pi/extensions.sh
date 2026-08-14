#!/usr/bin/env bash

if ! command -v pi >/dev/null 2>&1; then
	echo "pi is required but was not found in PATH" >&2
	exit 1
fi

exts=(
	npm:pi-autoresearch
	npm:pi-subagents
	https://github.com/Reidaa/pi-cliproxyapi.git
	git:github.com/DietrichGebert/ponytail
	https://github.com/Reidaa/pi-websearch.git
	https://github.com/Reidaa/pi-webfetch.git
	https://github.com/Reidaa/pi-question.git
)

for ext in "${exts[@]}"; do
	pi install "$ext"
done
