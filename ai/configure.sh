#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_file="${script_dir}/AGENTS.md"

destinations=(
	"${HOME}/.config/opencode/AGENTS.md"
)

for destination in "${destinations[@]}"; do
	mkdir -p "$(dirname -- "$destination")"
	cp "$source_file" "$destination"
	printf 'Updated %s\n' "$destination"
done


skills() {
	local skills=(
		emilkowalski/skills
		jakubkrehel/skills
		vercel-labs/opensrc
	)

	for skill in "${skills[@]}"; do
		npx skills@latest add "$skill" -y -g
	done
}

pi() {
	if ! command -v pi >/dev/null 2>&1; then
		echo "pi is required but was not found in PATH" >&2
		exit 1
	fi

	printf 'pi: Copying settings...\n'
	cp "${script_dir}/pi/settings.json" "${HOME}/.pi/agent/settings.json"

	printf 'pi: Installing extensions...\n'
	bash "${script_dir}/pi/extensions.sh"

	printf 'pi: Copying AGENTS.md...\n'
	cp "${script_dir}/AGENTS.md" "${HOME}/.pi/agent/AGENTS.md"
}

claude() {
	if ! command -v claude >/dev/null 2>&1; then
		echo "claude is required but was not found in PATH" >&2
		exit 1
	fi

	# printf 'claude: Copying settings...\n'
	# cp "${script_dir}/claude/settings.json" "${HOME}/.claude/settings.json"

	printf 'claude: Copying AGENTS.md...\n'
	cp "${script_dir}/AGENTS.md" "${HOME}/.claude/CLAUDE.md"


	claude_source="${script_dir}/claude/settings.json"
	claude_destination="${HOME}/.claude/settings.json"
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
}

codex() {
	if ! command -v codex >/dev/null 2>&1; then
		echo "codex is required but was not found in PATH" >&2
		exit 1
	fi

	printf 'codex: Copying AGENTS.md...\n'``
	
	mkdir -p "$HOME/.codex"

	rm -f "$HOME/.codex/config.toml"
	cp "${script_dir}/codex/config.toml" "$HOME/.codex/config.toml"

	printf 'Updated %s\n' "$HOME/.codex/config.toml"
	cp "${script_dir}/AGENTS.md" "$HOME/.codex/AGENTS.md"
}

# skills
pi
claude
codex