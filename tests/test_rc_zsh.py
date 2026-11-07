#!/usr/bin/env python3
"""Tests for zsh/rc.zsh. Run with: python3 tests/test_rc_zsh.py

Each test starts an interactive zsh with a fake HOME whose ~/.zshrc only
sources zsh/rc.zsh, the same line init.sh writes. PATH holds no real tools.
"""

from __future__ import annotations

import pathlib
import shutil
import subprocess
import tempfile
import unittest

RC_ZSH = pathlib.Path(__file__).resolve().parent.parent / "zsh" / "rc.zsh"
ZSH = shutil.which("zsh")


def write_tool(path: pathlib.Path, body: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"#!/bin/sh\n{body}\n")
    path.chmod(0o755)


@unittest.skipUnless(ZSH, "zsh is not installed")
class RcZshTests(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = pathlib.Path(tmp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        (self.home / ".zshrc").write_text(f'source "{RC_ZSH}"\n')
        self.empty_bin = self.root / "bin"
        self.empty_bin.mkdir()
        self.prefix = self.root / "homebrew"

    def zsh(self, command: str) -> subprocess.CompletedProcess[str]:
        # --no-globalrcs skips /etc/zshrc: distro files call tools that this
        # empty PATH does not have.
        return subprocess.run(
            [ZSH, "--no-globalrcs", "-i", "-c", command],
            # HOMEBREW_PREFIX keeps rc.zsh away from a real Homebrew on this machine.
            env={
                "HOME": str(self.home),
                "PATH": str(self.empty_bin),
                "HOMEBREW_PREFIX": str(self.prefix),
            },
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
        )

    def test_no_tools_installed_gives_no_errors(self) -> None:
        result = self.zsh("true")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")

    def test_homebrew_tools_are_on_path(self) -> None:
        # The fake brew puts its bin dir on PATH, like `brew shellenv` does.
        bin_dir = self.prefix / "bin"
        write_tool(
            bin_dir / "brew",
            f'[ "$1" = shellenv ] && echo \'export PATH="{bin_dir}:$PATH"\'',
        )
        write_tool(bin_dir / "eza", "true")

        result = self.zsh("whence -p eza")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(bin_dir / "eza"))

    def test_mise_activates_before_other_tools(self) -> None:
        # The fake mise (in ~/.local/bin, which rc.zsh puts on PATH) puts the
        # tools dir on PATH, like `mise activate` does.
        tools = self.root / "tools"
        write_tool(
            self.home / ".local/bin/mise",
            f'[ "$1" = activate ] && echo \'export PATH="{tools}:$PATH"\'',
        )
        write_tool(tools / "starship", "echo export STARSHIP_RAN=1")

        result = self.zsh('command -v starship && echo "$STARSHIP_RAN"')

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.split(), [str(tools / "starship"), "1"])


if __name__ == "__main__":
    unittest.main()
