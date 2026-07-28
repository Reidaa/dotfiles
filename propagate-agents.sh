#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_file="${script_dir}/llm/AGENTS.md"
claude_source="${script_dir}/llm/claude/settings.json"
claude_destination="${HOME}/.claude/settings.json"

if [[ ! -f $source_file ]]; then
	printf 'Source file not found: %s\n' "$source_file" >&2
	exit 1
fi

if [[ ! -f $claude_source ]]; then
	printf 'Claude settings file not found: %s\n' "$claude_source" >&2
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

claude_settings_sources=()
if [[ -f $claude_destination ]]; then
	claude_settings_sources+=("$claude_destination")
fi
claude_settings_sources+=("$claude_source")

temporary_settings="$(mktemp "${claude_destination}.tmp.XXXXXX")"
trap 'rm -f "$temporary_settings"' EXIT
jq -s 'reduce .[] as $settings ({}; . * $settings)' \
	"${claude_settings_sources[@]}" >"$temporary_settings"
mv "$temporary_settings" "$claude_destination"
trap - EXIT
printf 'Updated %s\n' "$claude_destination"
