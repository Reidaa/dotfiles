#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"

. "${repo_root}/.template/lib.sh"

REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
ZSH_PLUGINS_INSTALL_DIR="${HOME}/.local/zsh/plugins"
INSTALL_DIR="${ZSH_PLUGINS_INSTALL_DIR}/zsh-syntax-highlighting"

if [ ! -d "${HOME}/.local/zsh/plugins" ]; then
	mkdir -p "${ZSH_PLUGINS_INSTALL_DIR}"
fi

if [ ! -d "${INSTALL_DIR}" ]; then
	git clone "${REPO}" "${INSTALL_DIR}"
fi

if string_in_file "zsh-syntax-highlighting.zsh" "${HOME}/.zshrc"; then
	echo "zsh-syntax-highlighting already sourced in .zshrc"
else
	echo "source ${HOME}/.local/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >>"${HOME}/.zshrc"
fi
