#!/usr/bin/env bash

set -euo pipefail

# These plugins only work in zsh, so skip the install on other login shells.
case "${SHELL:-}" in
*/zsh) ;;
*)
	echo "login shell is not zsh (SHELL=${SHELL:-unset}), skipping" >&2
	exit 0
	;;
esac

plugins_dir="${HOME}/.local/zsh/plugins"
zshrc="${HOME}/.zshrc"

brew_prefix=""
if command -v brew >/dev/null 2>&1; then
	brew install zsh-autosuggestions zsh-syntax-highlighting
	brew_prefix="$(brew --prefix)"
else
	mkdir -p "$plugins_dir"
fi

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
	legacy_path="${plugins_dir}/${plugin}/${plugin}.zsh"
	if [ -n "$brew_prefix" ]; then
		plugin_path="${brew_prefix}/share/${plugin}/${plugin}.zsh"
	else
		target="${plugins_dir}/${plugin}"
		[ -d "$target" ] || git clone "https://github.com/zsh-users/${plugin}" "$target"
		plugin_path="$legacy_path"
	fi

	# Replace our old source lines in place and remove duplicates.
	python3 - "$zshrc" "$legacy_path" "$plugin_path" <<'PY'
import pathlib
import shlex
import sys

zshrc = pathlib.Path(sys.argv[1])
legacy_path, plugin_path = sys.argv[2:]
entry = f"source {shlex.quote(plugin_path)}\n"
known_entries = {
    f"source {quoted}"
    for path in (legacy_path, plugin_path)
    for quoted in (path, shlex.quote(path), f'"{path}"')
}
original = zshrc.read_text() if zshrc.exists() else ""
lines = []
found = False
for line in original.splitlines(keepends=True):
    if line.rstrip("\r\n") in known_entries:
        if not found:
            lines.append(entry)
            found = True
    else:
        lines.append(line)
updated = "".join(lines)
if not found:
    if updated and not updated.endswith("\n"):
        updated += "\n"
    updated += entry
if updated != original:
    zshrc.write_text(updated)
PY
done
