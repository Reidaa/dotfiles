#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

python3 "${repo_root}/.template/install_package.py" \
	--brew codex \
	--command codex \
	--script https://chatgpt.com/codex/install.sh

mkdir -p "$HOME/.codex"
ln -sfn "${script_dir}/config.toml" "$HOME/.codex/config.toml"
