#!/usr/bin/env python3
"""Tests for cli/brew/install.sh. Run with: python3 tests/test_brew_install.py

The installer runs with a fake HOME, a fake `uname` (to act as macOS or Linux),
and fake `curl` and `brew`, so nothing touches the real machine or network.
HOMEBREW_PREFIX points the installer at a temp dir instead of the real prefix.
"""

from __future__ import annotations

import pathlib
import subprocess
import tempfile
import unittest

REPO = pathlib.Path(__file__).resolve().parent.parent
INSTALLER = REPO / "cli" / "brew" / "install.sh"
BREWFILE = REPO / "cli" / "brew" / "Brewfile"
HOMEBREW_INSTALLER = (
    "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
)

# Fake brew: records its arguments, one call per line.
FAKE_BREW = '#!/bin/sh\necho "$*" >>"$HOME/brew-calls"\n'


def write_exe(path: pathlib.Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    path.chmod(0o755)


class BrewInstallTests(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = pathlib.Path(tmp.name)
        self.home = root / "home"
        self.home.mkdir()
        self.prefix = root / "homebrew"
        self.bin = root / "bin"

        # Fake uname: `uname -s` prints $FAKE_OS, `uname -m` prints arm64.
        write_exe(
            self.bin / "uname",
            '#!/bin/sh\n[ "$1" = -m ] && echo arm64 || echo "$FAKE_OS"\n',
        )
        # Fake curl: prints a stand-in for Homebrew's installer, which puts
        # the fake brew at $HOMEBREW_PREFIX/bin/brew, like the real one does.
        write_exe(
            self.bin / "curl",
            f'#!/bin/sh\necho "$*" >>"$HOME/curl-calls"\n'
            f"cat <<'EOF'\nmkdir -p \"$HOMEBREW_PREFIX/bin\"\n"
            f"cat >\"$HOMEBREW_PREFIX/bin/brew\" <<'BREW'\n{FAKE_BREW}BREW\n"
            f'chmod +x "$HOMEBREW_PREFIX/bin/brew"\nEOF\n',
        )

    def run_installer(self, os_name: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(INSTALLER)],
            check=False,
            cwd="/",
            env={
                "HOME": str(self.home),
                "PATH": f"{self.bin}:/usr/bin:/bin",
                "FAKE_OS": os_name,
                "HOMEBREW_PREFIX": str(self.prefix),
            },
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
        )

    def calls(self, name: str) -> list[str]:
        path = self.home / name
        return path.read_text().splitlines() if path.exists() else []

    def test_installs_brewfile_when_homebrew_is_present(self) -> None:
        for os_name in ("Linux", "Darwin"):
            with self.subTest(os_name):
                # Homebrew is in its prefix but not on PATH, as in a shell
                # that has not run `brew shellenv` yet.
                write_exe(self.prefix / "bin" / "brew", FAKE_BREW)
                (self.home / "brew-calls").unlink(missing_ok=True)

                result = self.run_installer(os_name)

                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.calls("curl-calls"), [])
                self.assertEqual(
                    self.calls("brew-calls"), [f"bundle --file={BREWFILE}"]
                )

    def test_installs_homebrew_first_when_missing(self) -> None:
        result = self.run_installer("Linux")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls("curl-calls"), [f"-fsSL {HOMEBREW_INSTALLER}"])
        self.assertEqual(self.calls("brew-calls"), [f"bundle --file={BREWFILE}"])


if __name__ == "__main__":
    unittest.main()
