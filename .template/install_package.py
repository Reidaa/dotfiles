#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import shlex
import shutil
import subprocess
import sys
from collections.abc import Sequence
from dataclasses import dataclass


USAGE = """\
Examples:
  install_package.py --brew just --apt rust-just --command just
  install_package.py --brew tealdeer --command tldr
  install_package.py --brew ripgrep --command rg
  install_package.py --brew fd --apt fd-find --command fd --command fdfind
  install_package.py --brew television --pacman television --command tv \\
      --command television --cargo television \\
      --script https://alexpasmantier.github.io/television/install.sh

Package managers are tried in priority order when multiple are given: Homebrew
first, then apt-get, dnf, yum, pacman, and apk. Use --brew package, --apt
package, --dnf package, --yum package, --pacman package, or --apk package to
allow specific package managers. Use --cargo crate or --script url as
fallbacks. Use --command cmd to skip installation when any of the listed
commands already exists; repeat the flag to list multiple commands.
"""


SUPPORTED_MANAGERS = ("apt-get", "dnf", "yum", "pacman", "apk")
PACKAGE_MANAGERS = ("brew", *SUPPORTED_MANAGERS)


@dataclass(frozen=True)
class PackageSpec:
    raw: str
    brew_name: str
    system_name: str
    options: dict[str, str]
    commands: tuple[str, ...] = ()

    @classmethod
    def from_options(
        cls, options: dict[str, str], commands: Sequence[str] | None = None
    ) -> "PackageSpec":
        option_names = {"apt-get": "apt"}
        raw_parts: list[str] = []
        command_values = (
            commands
            if commands is not None
            else [options["command"]]
            if "command" in options
            else []
        )
        configured_commands = tuple(
            dict.fromkeys(command for command in command_values if command)
        )

        for manager in PACKAGE_MANAGERS:
            package = options.get(manager)
            if package is not None:
                raw_parts.append(f"--{option_names.get(manager, manager)} {package}")

        for key in ("cargo", "script"):
            value = options.get(key)
            if value is not None:
                raw_parts.append(f"--{key} {value}")

        for command in configured_commands:
            raw_parts.append(f"--command {command}")

        default_name = (
            next(
                (
                    options[manager]
                    for manager in PACKAGE_MANAGERS
                    if manager in options
                ),
                None,
            )
            or options.get("cargo")
            or next(iter(configured_commands), None)
            or "package"
        )

        return cls(
            raw=" ".join(raw_parts),
            brew_name=default_name,
            system_name=default_name,
            options=options,
            commands=configured_commands,
        )


def command_exists(command: str) -> bool:
    return shutil.which(command) is not None


@dataclass(frozen=True)
class CommandRunner:
    dry_run: bool = False

    def run(self, command: list[str], *, shell: bool = False) -> bool:
        if self.dry_run:
            if shell:
                print(f"+ {command[0]}")
            else:
                print("+ " + shlex.join(command))
            return True

        try:
            return (
                subprocess.run(command[0] if shell else command, shell=shell).returncode
                == 0
            )
        except FileNotFoundError:
            executable = command[0]
            print(f"Command not found: {executable}", file=sys.stderr)
            return False


def resolve_package_name(spec: PackageSpec, package_manager: str) -> str:
    if package_manager in spec.options:
        return spec.options[package_manager]

    return spec.brew_name if package_manager == "brew" else spec.system_name


def installed_commands(spec: PackageSpec) -> list[str]:
    if spec.commands:
        return list(spec.commands)

    return list(
        dict.fromkeys(
            [
                *(
                    spec.options[manager]
                    for manager in PACKAGE_MANAGERS
                    if manager in spec.options
                ),
                *([spec.options["cargo"]] if "cargo" in spec.options else []),
            ]
        )
    )


def already_installed(spec: PackageSpec) -> str | None:
    for command in installed_commands(spec):
        if command_exists(command):
            return command

    return None


def allowed_package_managers(spec: PackageSpec) -> list[str]:
    return [manager for manager in PACKAGE_MANAGERS if manager in spec.options]


def iter_package_managers(spec: PackageSpec):
    for manager in allowed_package_managers(spec):
        if command_exists(manager):
            yield manager


def confirm(prompt: str) -> bool:
    try:
        reply = input(f"{prompt} [y/N] ")
    except EOFError:
        return False
    return reply.lower() in {"y", "yes"}


def root_command(command: list[str]) -> list[str]:
    if os.geteuid() == 0:
        return command
    return ["sudo", *command]


def install_with_package_manager(
    runner: CommandRunner, package_manager: str, package_name: str
) -> bool:
    if package_manager == "brew":
        return runner.run(["brew", "install", package_name])

    commands = {
        "apt-get": [
            root_command(["apt-get", "update"]),
            root_command(["apt-get", "install", "-y", package_name]),
        ],
        "dnf": [root_command(["dnf", "install", "-y", package_name])],
        "yum": [root_command(["yum", "install", "-y", package_name])],
        "pacman": [
            root_command(["pacman", "-S", "--needed", "--noconfirm", package_name])
        ],
        "apk": [root_command(["apk", "add", package_name])],
    }.get(package_manager)

    if commands is None:
        print(f"Unsupported package manager: {package_manager}", file=sys.stderr)
        return False

    return all(runner.run(command) for command in commands)


def display_package_name(spec: PackageSpec) -> str:
    allowed = allowed_package_managers(spec)
    if allowed:
        return resolve_package_name(spec, allowed[0])
    return (
        spec.options.get("cargo")
        or next(iter(installed_commands(spec)), None)
        or spec.options.get("script")
        or "package"
    )


def install_package_spec(spec: PackageSpec, runner: CommandRunner) -> bool:
    package_name = display_package_name(spec)

    installed_command = already_installed(spec)
    if installed_command:
        print(f"{package_name} already installed ({installed_command} found)")
        return True

    package_managers = list(iter_package_managers(spec))
    if not package_managers:
        failure_reason = f"No allowed package manager available for {spec.raw}"
    else:
        failure_reason = None
        for index, package_manager in enumerate(package_managers):
            manager_package_name = resolve_package_name(spec, package_manager)
            print(f"Installing {manager_package_name} with {package_manager}")
            if install_with_package_manager(
                runner, package_manager, manager_package_name
            ):
                return True
            if index < len(package_managers) - 1:
                print(
                    f"{package_manager} install failed for {manager_package_name}, trying the next package manager",
                    file=sys.stderr,
                )
            else:
                print(
                    f"{package_manager} install failed for {manager_package_name}, trying fallback installers",
                    file=sys.stderr,
                )
                failure_reason = (
                    f"{package_manager} install failed for {manager_package_name}"
                )

    cargo_package = spec.options.get("cargo")
    if cargo_package:
        if command_exists("cargo"):
            print(f"Installing {cargo_package} with Cargo")
            if runner.run(["cargo", "install", cargo_package]):
                return True
            print(
                f"Cargo install failed for {cargo_package}, trying fallback installers",
                file=sys.stderr,
            )
            failure_reason = f"Cargo install failed for {cargo_package}"
        else:
            failure_reason = f"Cargo is not available for {cargo_package}"

    install_script = spec.options.get("script")
    if install_script:
        if runner.dry_run or confirm(
            f"Install {package_name} by downloading and running {install_script}?"
        ):
            if runner.run(
                [
                    "bash",
                    "-o",
                    "pipefail",
                    "-c",
                    f"curl -fsSL {shlex.quote(install_script)} | bash",
                ]
            ):
                return True
            if failure_reason:
                print(failure_reason, file=sys.stderr)
            print(f"Script installer failed for {install_script}", file=sys.stderr)
            return False

        print("Installation cancelled.")
        return False

    if failure_reason:
        print(failure_reason, file=sys.stderr)
    print(f"No fallback installer available for {spec.raw}", file=sys.stderr)
    return False


def spec_from_args(args: argparse.Namespace) -> PackageSpec | None:
    raw_options: dict[str, str | None] = {
        "brew": args.brew,
        "apt-get": args.apt,
        "dnf": args.dnf,
        "yum": args.yum,
        "pacman": args.pacman,
        "apk": args.apk,
        "cargo": args.cargo,
        "script": args.script,
    }
    options: dict[str, str] = {}

    for key, value in raw_options.items():
        if value is not None:
            options[key] = value

    if not (
        any(manager in options for manager in PACKAGE_MANAGERS)
        or "cargo" in options
        or "script" in options
    ):
        return None

    return PackageSpec.from_options(options, commands=args.command)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install packages using allowed package managers, Cargo, or script fallback.",
        epilog=USAGE,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print install commands without executing them",
    )
    parser.add_argument("--brew", "--homebrew", metavar="PACKAGE")
    parser.add_argument("--apt", "--apt-get", dest="apt", metavar="PACKAGE")
    parser.add_argument("--dnf", metavar="PACKAGE")
    parser.add_argument("--yum", metavar="PACKAGE")
    parser.add_argument("--pacman", metavar="PACKAGE")
    parser.add_argument("--apk", metavar="PACKAGE")
    parser.add_argument("--cargo", metavar="CRATE")
    parser.add_argument("--script", metavar="URL")
    parser.add_argument(
        "--command",
        "--cmd",
        dest="command",
        action="append",
        metavar="COMMAND",
        help="command to check before installing; repeat to list multiple commands",
    )

    args = parser.parse_args(argv)
    if spec_from_args(args) is None:
        parser.error(
            "provide at least one installer flag such as --brew, --cargo, or --script"
        )

    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    runner = CommandRunner(dry_run=args.dry_run)

    package_spec = spec_from_args(args)
    assert package_spec is not None

    if not install_package_spec(package_spec, runner):
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
