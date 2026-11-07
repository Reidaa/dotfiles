#!/usr/bin/env python3
"""Tests for cli/brew/install.sh. Run with: python3 tests/test_brew_install.py

The installer runs with a fake HOME, a fake `brew` and a fake `curl`, so
nothing touches the real machine or network. HOMEBREW_PREFIX points the
installer at a temp dir instead of the real Homebrew prefix.
"""

from __future__ import annotations

import pathlib
import subprocess
import tempfile
import unittest

REPO = pathlib.Path(__file__).resolve().parent.parent
INSTALLER = REPO / "cli" / "brew" / "install.sh"
BREWFILE = REPO / "cli" / "brew" / "Brewfile"


def write_exe(path: pathlib.Path, name: str) -> None:
    """Writes a fake command that records its arguments in $HOME/<name>-calls."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f'#!/bin/sh\necho "$*" >>"$HOME/{name}-calls"\n')
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
        # Fake curl, to prove that the installer downloads nothing.
        write_exe(self.bin / "curl", "curl")

    def run_installer(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(INSTALLER)],
            check=False,
            cwd="/",
            env={
                "HOME": str(self.home),
                "PATH": f"{self.bin}:/usr/bin:/bin",
                "HOMEBREW_PREFIX": str(self.prefix),
            },
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
        )

    def calls(self, name: str) -> list[str]:
        path = self.home / f"{name}-calls"
        return path.read_text().splitlines() if path.exists() else []

    def test_installs_brewfile_when_homebrew_is_present(self) -> None:
        # Homebrew is in its prefix but not on PATH, as in a shell that has
        # not run `brew shellenv` yet.
        write_exe(self.prefix / "bin" / "brew", "brew")

        result = self.run_installer()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls("brew"), [f"bundle --file={BREWFILE}"])

    def test_missing_homebrew_reports_and_fails_without_installing(self) -> None:
        result = self.run_installer()

        self.assertEqual(result.returncode, 1)
        self.assertIn("https://brew.sh", result.stderr)
        self.assertEqual(self.calls("curl"), [])


if __name__ == "__main__":
    unittest.main()
