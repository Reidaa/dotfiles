#!/usr/bin/env bash

set -euo pipefail

prompt="come up with a commit message. Use conventional commits. Avoid overly verbose descriptions or unnecessary details."

if ! command -v opencode >/dev/null 2>&1; then
	echo "opencode is required but was not found in PATH" >&2
	exit 127
fi

exec opencode run --agent build -m "openai/gpt-5.6-sol" "$prompt"
