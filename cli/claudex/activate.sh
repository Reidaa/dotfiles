#!/usr/bin/env bash

claudex_config="${XDG_CONFIG_HOME:-${HOME}/.config}/claudex/config.zsh"

if [[ -r $claudex_config ]]; then
	# The path points to the user's private runtime configuration.
	# shellcheck disable=SC1090
	source "$claudex_config"
fi

_claudex() {
	if [[ -z ${CLAUDEX_API_KEY:-} ]]; then
		echo "claudex: set CLAUDEX_API_KEY" >&2
		return 1
	fi

	local base_url="${CLAUDEX_BASE_URL:-http://127.0.0.1:8317}"
	local model="${CLAUDEX_MODEL:-gpt-5.6-sol}"
	local subagent_model="${CLAUDEX_SUBAGENT_MODEL:-$model}"
	local concurrency="${CLAUDEX_MAX_TOOL_USE_CONCURRENCY:-3}"
	local tool_search="${CLAUDEX_ENABLE_TOOL_SEARCH:-false}"

	if ! command -v claude >/dev/null 2>&1; then
		echo "claudex: Claude Code is not installed or is not in PATH" >&2
		return 127
	fi

	ANTHROPIC_BASE_URL="$base_url" \
		ANTHROPIC_AUTH_TOKEN="$CLAUDEX_API_KEY" \
		ANTHROPIC_DEFAULT_OPUS_MODEL="$model" \
		ANTHROPIC_DEFAULT_SONNET_MODEL="$model" \
		ANTHROPIC_DEFAULT_HAIKU_MODEL="$model" \
		CLAUDE_CODE_SUBAGENT_MODEL="$subagent_model" \
		CLAUDE_CODE_ALWAYS_ENABLE_EFFORT="${CLAUDEX_ALWAYS_ENABLE_EFFORT:-1}" \
		CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY="$concurrency" \
		ENABLE_TOOL_SEARCH="$tool_search" \
		command claude --dangerously-skip-permissions --model "$model" "$@"
}

alias claudex='CLAUDEX_SUBAGENT_MODEL=gpt-5.6-terra _claudex'
alias claude-kimi="CLAUDEX_MODEL=kimi-k3 CLAUDEX_SUBAGENT_MODEL=kimi-k3 _claudex"
