#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

ln -sfn "${script_dir}/tmux.conf" "$HOME/.tmux.conf"
