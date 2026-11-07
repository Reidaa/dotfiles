#!/usr/bin/env python3
"""Tests for the curl | bash bootstrap. Run with: python3 tests/test_install.py

Each test pipes install.sh into bash (like `curl ... | bash`) with a fake HOME,
a local fixture repo, and a fake Homebrew prefix (HOMEBREW_PREFIX), so nothing
touches the real machine or network.
"""

from __future__ import annotations

import pathlib
import subprocess
import tempfile
import unittest

INSTALL_SH = pathlib.Path(__file__).resolve().parent.parent / "install.sh"


def git(*args: str, cwd: pathlib.Path) -> None:
    subprocess.run(
        ["git", "-c", "user.name=t", "-c", "user.email=t@t", *args],
        cwd=cwd,
        check=True,
        capture_output=True,
    )


class InstallTests(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = pathlib.Path(tmp.name)
        self.home = root / "home"
        self.home.mkdir()
        self.dest = self.home / ".dotfiles"

        # Fake Homebrew: install.sh only checks that brew exists.
        self.prefix = root / "homebrew"
        brew = self.prefix / "bin" / "brew"
        brew.parent.mkdir(parents=True)
        brew.write_text("#!/bin/sh\n")
        brew.chmod(0o755)

        # Fixture repo: its init.sh only records that it ran.
        self.source = root / "source"
        self.source.mkdir()
        (self.source / "init.sh").write_text('echo ran >>"$HOME/init-ran"\n')
        git("init", "-q", "-b", "main", cwd=self.source)
        git("add", ".", cwd=self.source)
        git("commit", "-q", "-m", "init", cwd=self.source)

    def run_install(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash"],
            check=False,
            input=INSTALL_SH.read_text(),
            env={
                "HOME": str(self.home),
                "PATH": "/usr/bin:/bin",
                "DOTFILES_REPO": str(self.source),
                "HOMEBREW_PREFIX": str(self.prefix),
            },
            capture_output=True,
            text=True,
        )

    def init_runs(self) -> int:
        marker = self.home / "init-ran"
        return len(marker.read_text().splitlines()) if marker.exists() else 0

    def test_fresh_install_clones_and_runs_init(self) -> None:
        result = self.run_install()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.dest / ".git").is_dir())
        self.assertEqual(self.init_runs(), 1)

    def test_rerun_pulls_updates_and_runs_init_again(self) -> None:
        self.run_install()
        (self.source / "new-file").write_text("x\n")
        git("add", ".", cwd=self.source)
        git("commit", "-q", "-m", "update", cwd=self.source)

        result = self.run_install()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.dest / "new-file").exists())
        self.assertEqual(self.init_runs(), 2)

    def test_missing_homebrew_reports_and_exits_before_cloning(self) -> None:
        (self.prefix / "bin" / "brew").unlink()

        result = self.run_install()

        self.assertEqual(result.returncode, 1)
        self.assertIn("https://brew.sh", result.stderr)
        self.assertFalse(self.dest.exists())
        self.assertEqual(self.init_runs(), 0)

    def test_existing_non_git_directory_is_left_alone(self) -> None:
        self.dest.mkdir()
        (self.dest / "mine").write_text("keep\n")

        result = self.run_install()

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(sorted(p.name for p in self.dest.iterdir()), ["mine"])
        self.assertEqual(self.init_runs(), 0)


if __name__ == "__main__":
    unittest.main()
