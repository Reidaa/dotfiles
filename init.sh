#!/bin/bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
shell=$(basename "$SHELL")

. "${script_dir}/.template/lib.sh"

. "${script_dir}/zsh/autosuggestions/install.sh"
. "${script_dir}/zsh/syntax-highlighting/install.sh"
. "${script_dir}/starship/install.sh"
. "${script_dir}/cli/mise/install.sh"
. "${script_dir}/cli/atuin/install.sh"
# . my/install.sh
