#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

exec "${repo_root}/.template/install_package.sh" \
	--brew television \
	--command tv \
	--command television \
	--pacman television \
	--cargo television \
	--script https://alexpasmantier.github.io/television/install.sh
