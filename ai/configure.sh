#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_file="${script_dir}/AGENTS.md"

# Symlinks a repo file to a destination, so edits in the repo apply right away.
# Replaces any existing file at the destination.
link_file() {
	local source="$1"
	local destination="$2"
	mkdir -p "$(dirname -- "$destination")"
	ln -sfn "$source" "$destination"
	printf 'Linked %s -> %s\n' "$destination" "$source"
}

# Symlinks AGENTS.md to an agent's global instruction file.
link_agents_md() {
	link_file "$source_file" "$1"
}

skills() {
	local skills=(
		emilkowalski/skills
		jakubkrehel/skills
		vercel-labs/opensrc
		michaelshimeles/skills
		danyuchn/asd-ste100-skill
		reidaa/agent-skills
	)

	for skill in "${skills[@]}"; do
		npx skills@latest add -g "$skill"
	done
}

claude() {
	if ! command -v claude >/dev/null 2>&1; then
		echo "claude is required but was not found in PATH" >&2
		exit 1
	fi

	link_agents_md "${HOME}/.claude/CLAUDE.md"
}

codex() {
	if ! command -v codex >/dev/null 2>&1; then
		echo "codex is required but was not found in PATH" >&2
		exit 1
	fi

	link_agents_md "$HOME/.codex/AGENTS.md"
}

opencode() {
	if ! command -v opencode >/dev/null 2>&1; then
		echo "opencode is required but was not found in PATH" >&2
		exit 1
	fi

	link_agents_md "${HOME}/.config/opencode/AGENTS.md"
}

skills
claude
codex
opencode
