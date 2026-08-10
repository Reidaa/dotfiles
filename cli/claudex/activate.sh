# shellcheck shell=bash
# Sourced from ~/.zshrc; config lives next to this file (gitignored).

claudex_config="${0:A:h}/config.zsh"

if [[ -r $claudex_config ]]; then
	# shellcheck disable=SC1090
	source "$claudex_config"
fi

claudex() {
	# Secrets and endpoints must come from the config; knobs below have defaults.
	local missing=""
	for v in CLAUDEX_API_KEY CLAUDEX_BASE_URL CLAUDEX_MODEL; do
		[[ -n ${(P)v} ]] || missing+=" $v"
	done

	if [[ -n $missing ]]; then
		echo "claudex: missing$missing" >&2
		return 1
	fi

	if ! command -v claude >/dev/null 2>&1; then
		echo "claudex: Claude Code is not installed or is not in PATH" >&2
		return 127
	fi

	ANTHROPIC_BASE_URL="$CLAUDEX_BASE_URL" \
		ANTHROPIC_AUTH_TOKEN="$CLAUDEX_API_KEY" \
		ANTHROPIC_DEFAULT_OPUS_MODEL="$CLAUDEX_MODEL" \
		ANTHROPIC_DEFAULT_SONNET_MODEL="$CLAUDEX_MODEL" \
		ANTHROPIC_DEFAULT_HAIKU_MODEL="$CLAUDEX_MODEL" \
		CLAUDE_CODE_SUBAGENT_MODEL="${CLAUDEX_SUBAGENT_MODEL:-$CLAUDEX_MODEL}" \
		CLAUDE_CODE_ALWAYS_ENABLE_EFFORT="${CLAUDEX_ALWAYS_ENABLE_EFFORT:-1}" \
		CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY="${CLAUDEX_MAX_TOOL_USE_CONCURRENCY:-3}" \
		ENABLE_TOOL_SEARCH="${CLAUDEX_ENABLE_TOOL_SEARCH:-false}" \
		command claude --dangerously-skip-permissions --model "$CLAUDEX_MODEL" "$@"
}

# Same proxy, but for Codex. CLAUDEX_MODEL's "name(effort)" syntax is split
# into Codex's separate model / reasoning-effort settings.
codexx() {
	local missing=""
	for v in CLAUDEX_API_KEY CLAUDEX_BASE_URL CLAUDEX_MODEL; do
		[[ -n ${(P)v} ]] || missing+=" $v"
	done

	if [[ -n $missing ]]; then
		echo "codexx: missing$missing" >&2
		return 1
	fi

	if ! command -v codex >/dev/null 2>&1; then
		echo "codexx: Codex is not installed or is not in PATH" >&2
		return 127
	fi

	local model="${CLAUDEX_MODEL%%\(*}"
	local effort="${${CLAUDEX_MODEL#*\(}%\)}"
	[[ $effort == "$CLAUDEX_MODEL" ]] && effort="medium"

	command codex --yolo \
		-c model="$model" \
		-c model_reasoning_effort="$effort" \
		-c model_provider=cliproxy \
		-c model_providers.cliproxy.name=CLIProxyAPI \
		-c model_providers.cliproxy.base_url="${CLAUDEX_BASE_URL}/v1" \
		-c model_providers.cliproxy.env_key=CLAUDEX_API_KEY \
		-c model_providers.cliproxy.wire_api=responses \
		"$@"
}
