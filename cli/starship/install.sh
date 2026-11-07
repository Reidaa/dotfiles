#!/usr/bin/env bash
# Links the starship prompt config. Homebrew installs starship itself and
# zsh/rc.zsh activates it.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.config"
ln -sfn "${script_dir}/starship.toml" "$HOME/.config/starship.toml"
