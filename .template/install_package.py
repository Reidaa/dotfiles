#!/usr/bin/env python3
"""Install a package with the first available package manager, else Cargo, else a script."""

from __future__ import annotations

import argparse
import os
import shlex
import shutil
import subprocess
import sys


def sudo(command: list[str]) -> list[str]:
    return command if os.geteuid() == 0 else ["sudo", *command]


# Package managers in priority order, each mapped to the commands that install a package.
MANAGERS = {
    "brew": lambda pkg: [["brew", "install", pkg]],
    "apt": lambda pkg: [
        sudo(["apt-get", "update"]),
        sudo(["apt-get", "install", "-y", pkg]),
    ],
    "dnf": lambda pkg: [sudo(["dnf", "install", "-y", pkg])],
    "pacman": lambda pkg: [sudo(["pacman", "-S", "--needed", "--noconfirm", pkg])],
    "apk": lambda pkg: [sudo(["apk", "add", pkg])],
}
# The binary to look for in PATH, where it differs from the flag name.
BINARIES = {"apt": "apt-get"}


def run(command: list[str]) -> bool:
    try:
        return subprocess.run(command, check=False).returncode == 0
    except FileNotFoundError:
        print(f"Command not found: {command[0]}", file=sys.stderr)
        return False


def confirm(prompt: str) -> bool:
    try:
        return input(f"{prompt} [y/N] ").lower() in {"y", "yes"}
    except EOFError:
        return False


def install(args: argparse.Namespace) -> bool:
    packages = {name: getattr(args, name) for name in MANAGERS if getattr(args, name)}

    # Nothing to do when one of the commands the package provides is already on PATH.
    # Without --command, guess the command from the package names.
    candidates = args.command or [*packages.values(), *filter(None, [args.cargo])]
    for command in dict.fromkeys(candidates):
        if shutil.which(command):
            print(f"{command} already installed")
            return True

    for name, package in packages.items():
        if not shutil.which(BINARIES.get(name, name)):
            continue
        print(f"Installing {package} with {name}")
        if all(run(command) for command in MANAGERS[name](package)):
            return True
        print(f"{name} install failed for {package}", file=sys.stderr)

    if args.cargo:
        if shutil.which("cargo"):
            print(f"Installing {args.cargo} with Cargo")
            if run(["cargo", "install", args.cargo]):
                return True
        print(f"Cargo install failed for {args.cargo}", file=sys.stderr)

    if args.script:
        if not confirm(f"Download and run {args.script}?"):
            print("Installation cancelled.")
            return False
        return run(
            [
                "bash",
                "-o",
                "pipefail",
                "-c",
                f"curl -fsSL {shlex.quote(args.script)} | bash",
            ]
        )

    print("No installer available", file=sys.stderr)
    return False


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in MANAGERS:
        parser.add_argument(f"--{name}", metavar="PACKAGE")
    parser.add_argument("--cargo", metavar="CRATE")
    parser.add_argument("--script", metavar="URL")
    parser.add_argument(
        "--command",
        action="append",
        metavar="COMMAND",
        help="command to check before installing; repeat for several",
    )

    args = parser.parse_args(argv)
    if not any(getattr(args, name) for name in (*MANAGERS, "cargo", "script")):
        parser.error(
            "provide at least one installer flag such as --brew, --cargo or --script"
        )
    return args


def main(argv: list[str] | None = None) -> int:
    return 0 if install(parse_args(sys.argv[1:] if argv is None else argv)) else 1


if __name__ == "__main__":
    raise SystemExit(main())
