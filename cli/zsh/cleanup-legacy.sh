#!/usr/bin/env bash

set -euo pipefail

# Run after installing the Homebrew plugins, independently or from install.sh.
zshrc="${HOME}/.zshrc"
[ -f "$zshrc" ] || exit 0
brew_prefix="${1:-$(brew --prefix)}"

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
	legacy_path="${HOME}/.local/zsh/plugins/${plugin}/${plugin}.zsh"
	plugin_path="${brew_prefix}/share/${plugin}/${plugin}.zsh"
	# Keep the old source line until its replacement is installed.
	[ -f "$plugin_path" ] || continue
	printf -v entry 'source %q' "$plugin_path"

	python3 - "$zshrc" "$legacy_path" "$plugin_path" "$entry" <<'PY'
import pathlib
import shlex
import sys

zshrc = pathlib.Path(sys.argv[1])
legacy_path, plugin_path, entry = sys.argv[2:]
known_entries = {entry} | {
    f"source {quoted}"
    for path in (legacy_path, plugin_path)
    for quoted in (path, shlex.quote(path), f'"{path}"')
}
original = zshrc.read_text()
lines = []
found = False
for line in original.splitlines(keepends=True):
    if line.rstrip("\r\n") in known_entries:
        if not found:
            lines.append(entry + "\n")
            found = True
    else:
        lines.append(line)
updated = "".join(lines)
if updated != original:
    zshrc.write_text(updated)
PY
done
