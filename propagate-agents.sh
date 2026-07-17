#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_file="${script_dir}/AGENTS.md"

if [[ ! -f "$source_file" ]]; then
	printf 'Source file not found: %s\n' "$source_file" >&2
	exit 1
fi

destinations=(
	"${HOME}/.codex/AGENTS.md"
	"${HOME}/.claude/CLAUDE.md"
	"${HOME}/.config/opencode/AGENTS.md"
)

for destination in "${destinations[@]}"; do
	mkdir -p "$(dirname -- "$destination")"
	cp "$source_file" "$destination"
	printf 'Updated %s\n' "$destination"
done
