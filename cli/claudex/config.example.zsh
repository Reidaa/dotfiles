# shellcheck shell=bash

# Copied to cli/claudex/config.zsh (gitignored) by install.sh.
# Use the same key here and in CLIProxyAPI's `api-keys` configuration.
export CLAUDEX_API_KEY=""

export CLAUDEX_BASE_URL="http://127.0.0.1:8317"
# Append a "(level)" suffix to set the reasoning effort, e.g. "gpt-5.6-luna(max)";
# CLIProxyAPI parses it from the model name, Claude Code's /effort is ignored.
export CLAUDEX_MODEL="gpt-5.6-sol(high)"
export CLAUDEX_SUBAGENT_MODEL="gpt-5.6-luna(max)"
export CLAUDEX_ALWAYS_ENABLE_EFFORT="1"
export CLAUDEX_MAX_TOOL_USE_CONCURRENCY="3"
export CLAUDEX_ENABLE_TOOL_SEARCH="false"
