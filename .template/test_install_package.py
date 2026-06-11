#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import contextlib
import io
import pathlib
import sys
import unittest
from unittest import mock


MODULE_PATH = pathlib.Path(__file__).with_name("install_package.py")
SPEC = importlib.util.spec_from_file_location("install_package", MODULE_PATH)
assert SPEC is not None
install_package = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = install_package
SPEC.loader.exec_module(install_package)


class FakeRunner:
    dry_run = True

    def __init__(self, *, commands: set[str] | None = None, run_result: bool = True):
        self.commands = commands or set()
        self.run_result = run_result
        self.runs: list[list[str]] = []

    def command_exists(self, command: str) -> bool:
        return command in self.commands

    def run(self, command: list[str], *, shell: bool = False) -> bool:
        assert not shell
        self.runs.append(command)
        return self.run_result


class InstallPackageTests(unittest.TestCase):
    def test_confirm_treats_eof_as_negative_answer(self) -> None:
        with mock.patch("builtins.input", side_effect=EOFError):
            self.assertFalse(install_package.confirm("Install?"))

    def test_cargo_only_spec_is_allowed_and_named_from_cargo(self) -> None:
        args = install_package.parse_args(["--cargo", "television"])
        spec = install_package.spec_from_args(args)

        self.assertIsNotNone(spec)
        assert spec is not None
        self.assertEqual("television", install_package.display_package_name(spec))
        self.assertEqual(["television"], install_package.installed_commands(spec))

    def test_command_only_spec_is_rejected(self) -> None:
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            install_package.parse_args(["--command", "television"])

    def test_script_only_spec_does_not_check_script_basename_on_path(self) -> None:
        runner = FakeRunner(commands={"install.sh"})
        spec = install_package.PackageSpec.from_options(
            {"script": "https://example.com/install.sh"}
        )

        self.assertEqual([], install_package.installed_commands(spec))

        with mock.patch.object(install_package, "confirm", return_value=True):
            self.assertTrue(install_package.install_package_spec(spec, runner))

        self.assertEqual(["bash", "-o", "pipefail", "-c"], runner.runs[0][:4])
        self.assertIn(
            "curl -fsSL https://example.com/install.sh | bash",
            runner.runs[0][4],
        )

    def test_pacman_uses_needed_without_database_sync(self) -> None:
        runner = FakeRunner()

        with mock.patch.object(install_package.os, "geteuid", return_value=0):
            self.assertTrue(
                install_package.install_with_package_manager(runner, "pacman", "fd")
            )

        self.assertEqual(
            [["pacman", "-S", "--needed", "--noconfirm", "fd"]],
            runner.runs,
        )

    def test_script_fallback_uses_bash_pipefail(self) -> None:
        runner = FakeRunner()
        spec = install_package.PackageSpec.from_options(
            {
                "script": "https://example.com/install.sh?name=two words",
                "command": "example",
            }
        )

        self.assertTrue(install_package.install_package_spec(spec, runner))

        self.assertEqual(["bash", "-o", "pipefail", "-c"], runner.runs[0][:4])
        self.assertIn(
            "curl -fsSL 'https://example.com/install.sh?name=two words' | bash",
            runner.runs[0][4],
        )


if __name__ == "__main__":
    unittest.main()
