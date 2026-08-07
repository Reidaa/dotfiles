#!/usr/bin/env python3
"""Run with: python3 .template/test_install_package.py"""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest
from unittest import mock

MODULE_PATH = pathlib.Path(__file__).with_name("install_package.py")
SPEC = importlib.util.spec_from_file_location("install_package", MODULE_PATH)
install_package = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = install_package
SPEC.loader.exec_module(install_package)


def install(
    argv: list[str], *, on_path: set[str], run_results: list[bool] | None = None
):
    """Run install() with a fake PATH and fake command execution; returns (ok, commands run)."""
    runs: list[list[str]] = []
    results = list(run_results or [])

    def fake_run(command: list[str]) -> bool:
        runs.append(command)
        return results.pop(0) if results else True

    with (
        mock.patch.object(install_package, "run", fake_run),
        mock.patch.object(
            install_package.shutil, "which", lambda c: c if c in on_path else None
        ),
    ):
        ok = install_package.install(install_package.parse_args(argv))
    return ok, runs


class InstallPackageTests(unittest.TestCase):
    def test_skips_when_command_already_on_path(self) -> None:
        ok, runs = install(
            ["--brew", "ripgrep", "--command", "rg"], on_path={"rg", "brew"}
        )
        self.assertTrue(ok)
        self.assertEqual(runs, [])

    def test_prefers_brew_over_apt(self) -> None:
        ok, runs = install(
            ["--brew", "just", "--apt", "rust-just"], on_path={"brew", "apt-get"}
        )
        self.assertTrue(ok)
        self.assertEqual(runs, [["brew", "install", "just"]])

    def test_falls_back_to_cargo_when_manager_fails(self) -> None:
        ok, runs = install(
            ["--brew", "dua-cli", "--cargo", "dua-cli", "--command", "dua"],
            on_path={"brew", "cargo"},
            run_results=[False, True],
        )
        self.assertTrue(ok)
        self.assertEqual(runs[-1], ["cargo", "install", "dua-cli"])

    def test_script_fallback_needs_confirmation(self) -> None:
        with mock.patch("builtins.input", side_effect=EOFError):
            ok, runs = install(["--script", "https://mise.run"], on_path=set())
        self.assertFalse(ok)
        self.assertEqual(runs, [])


if __name__ == "__main__":
    unittest.main()
