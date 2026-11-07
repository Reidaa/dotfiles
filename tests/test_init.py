#!/usr/bin/env python3
"""Tests for init.sh. Run with: python3 tests/test_init.py

Each test copies init.sh into a fixture repo whose installers only log their
name, and runs it with a fake HOME, so nothing touches the real machine.
"""

from __future__ import annotations

import pathlib
import subprocess
import tempfile
import unittest

INIT_SH = pathlib.Path(__file__).resolve().parent.parent / "init.sh"


class InitTests(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = pathlib.Path(tmp.name)
        self.home = root / "home"
        self.home.mkdir()
        self.repo = root / "repo"
        self.repo.mkdir()
        (self.repo / "init.sh").write_text(INIT_SH.read_text())
        self.log = root / "log"
        # Named so that a plain sort would put "aaa" before "brew".
        for name in ("aaa", "brew", "zzz"):
            self.add_installer(f"cli/{name}/install.sh")
        self.add_installer("my/install.sh")

    def add_installer(self, rel: str, exit_code: int = 0) -> None:
        path = self.repo / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f'echo {rel} >>"{self.log}"\nexit {exit_code}\n')

    def run_init(self) -> subprocess.CompletedProcess[str]:
        # Run from another directory: init.sh must not depend on the cwd (C1).
        return subprocess.run(
            ["bash", str(self.repo / "init.sh")],
            check=False,
            cwd=self.home,
            env={"HOME": str(self.home), "PATH": "/usr/bin:/bin"},
            capture_output=True,
            text=True,
        )

    def ran(self) -> list[str]:
        return self.log.read_text().splitlines()

    def test_adds_one_source_line_to_zshrc_once(self) -> None:
        self.run_init()
        result = self.run_init()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            (self.home / ".zshrc").read_text(),
            f'source "{self.repo}/zsh/rc.zsh"\n',
        )

    def test_keeps_existing_zshrc_content(self) -> None:
        (self.home / ".zshrc").write_text("export MINE=1")

        self.run_init()

        self.assertEqual(
            (self.home / ".zshrc").read_text(),
            f'export MINE=1\nsource "{self.repo}/zsh/rc.zsh"\n',
        )

    def test_runs_brew_first_then_cli_then_my(self) -> None:
        self.run_init()

        self.assertEqual(
            self.ran(),
            [
                "cli/brew/install.sh",
                "cli/aaa/install.sh",
                "cli/zzz/install.sh",
                "my/install.sh",
            ],
        )

    def test_failure_does_not_stop_other_installers(self) -> None:
        self.add_installer("cli/brew/install.sh", exit_code=1)
        self.add_installer("cli/aaa/install.sh", exit_code=3)

        result = self.run_init()

        self.assertEqual(result.returncode, 1)
        self.assertEqual(len(self.ran()), 4)
        # The summary is the text after the "failed:" heading.
        summary = result.stderr.split("failed:")[-1]
        self.assertNotEqual(summary, result.stderr)
        self.assertIn("cli/brew/install.sh", summary)
        self.assertIn("cli/aaa/install.sh", summary)
        self.assertNotIn("cli/zzz/install.sh", summary)


if __name__ == "__main__":
    unittest.main()
