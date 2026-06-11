#!/usr/bin/env bash

set -euo pipefail

install_package_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
install_package_python="${install_package_script_dir}/install_package.py"

install_package() {
	python3 "${install_package_python}" "$@"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	install_package "$@"
fi
