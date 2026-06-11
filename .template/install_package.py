#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import platform
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


USAGE = """\
Flag format:
  --brew package [--apt package] [--dnf package] [--command cmd]

Package spec format:
  brew-package
  brew-package:system-package
  brew-package:system-package,command=cmd|cmd,system=manager|manager,cargo=crate,script=url

Examples:
  install_package.py --brew just --apt rust-just --command just
  install_package.py --brew tealdeer --command tldr
  install_package.py ripgrep
  install_package.py 'fd:fd-find,command=fd|fdfind' bat
  install_package.py 'television:television,command=tv|television,system=pacman,cargo=television,script=https://alexpasmantier.github.io/television/install.sh'

Package managers are tried in priority order when multiple are given: Homebrew
first, then apt-get, dnf, yum, pacman, and apk. Use --brew package, --apt
package, --dnf package, --yum package, --pacman package, or --apk package to
allow specific package managers. Use --cargo crate, --script url, cargo=crate,
or script=url as fallbacks. Use --command cmd or command=cmd|cmd to skip
installation when any of the listed commands already exists.
"""


SUPPORTED_MANAGERS = ("apt-get", "dnf", "yum", "pacman", "apk")
PACKAGE_MANAGERS = ("brew", *SUPPORTED_MANAGERS)

TARGET_ALIASES = {
    "apt-get": {
        "apt",
        "apt-get",
        "debian",
        "ubuntu",
        "linuxmint",
        "pop",
        "elementary",
        "zorin",
        "raspbian",
        "kali",
        "devuan",
    },
    "dnf": {"dnf", "fedora"},
    "yum": {"yum", "rhel", "centos", "rocky", "almalinux", "ol"},
    "pacman": {"arch", "manjaro", "endeavouros", "garuda", "artix", "pacman"},
    "apk": {"apk", "alpine"},
}

PACKAGE_OVERRIDE_KEYS = frozenset(
    {"brew", "homebrew", *SUPPORTED_MANAGERS}
    | {alias for aliases in TARGET_ALIASES.values() for alias in aliases}
)


@dataclass(frozen=True)
class PackageSpec:
    raw: str
    brew_name: str
    system_name: str
    options: dict[str, str]

    @classmethod
    def parse(cls, raw: str) -> "PackageSpec":
        parts = raw.split(",")
        base_spec = parts[0]

        if ":" in base_spec:
            brew_name, system_name = base_spec.split(":", 1)
        else:
            brew_name = system_name = base_spec

        options: dict[str, str] = {}
        for option in parts[1:]:
            if "=" not in option:
                continue
            key, value = option.split("=", 1)
            options[key.lower()] = value

        return cls(
            raw=raw, brew_name=brew_name, system_name=system_name, options=options
        )

    @classmethod
    def from_options(cls, options: dict[str, str]) -> "PackageSpec":
        option_names = {"apt-get": "apt", "brew": "brew"}
        raw_parts: list[str] = []

        for manager in PACKAGE_MANAGERS:
            package = options.get(manager)
            if package is not None:
                raw_parts.append(f"--{option_names.get(manager, manager)} {package}")

        for key in ("cargo", "script", "command"):
            value = options.get(key)
            if value is not None:
                raw_parts.append(f"--{key} {value}")

        default_name = next(
            (options[manager] for manager in PACKAGE_MANAGERS if manager in options),
            "package",
        )

        return cls(
            raw=" ".join(raw_parts),
            brew_name=default_name,
            system_name=default_name,
            options=options,
        )


@dataclass(frozen=True)
class CommandRunner:
    dry_run: bool = False

    def command_exists(self, command: str) -> bool:
        return shutil.which(command) is not None

    def run(self, command: list[str], *, shell: bool = False) -> bool:
        if self.dry_run:
            if shell:
                print(f"+ {command[0]}")
            else:
                print("+ " + shlex.join(command))
            return True

        return (
            subprocess.run(command[0] if shell else command, shell=shell).returncode
            == 0
        )


def read_os_release(path: str = "/etc/os-release") -> dict[str, str]:
    os_release: dict[str, str] = {}
    release_path = Path(path)
    if not release_path.is_file():
        return os_release

    for line in release_path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os_release[key] = shlex.split(value)[0] if value else ""

    return os_release


def detect_platform_key(os_release_path: str = "/etc/os-release") -> str:
    os_release = read_os_release(os_release_path)
    platform_key = os_release.get("ID", "")
    if platform_key:
        return platform_key

    system_name = platform.system()
    if system_name == "Darwin":
        return "macos"

    return system_name.lower()


def target_matches(target: str, package_manager: str, platform_key: str) -> bool:
    normalized_target = target.lower()
    if normalized_target in {package_manager, platform_key}:
        return True
    if normalized_target in {"brew", "homebrew"}:
        return package_manager == "brew"

    aliases = TARGET_ALIASES.get(package_manager, set[str]())
    return normalized_target in aliases


def resolve_package_name(
    spec: PackageSpec, package_manager: str, platform_key: str
) -> str:
    if package_manager in spec.options:
        return spec.options[package_manager]

    package_name = spec.brew_name if package_manager == "brew" else spec.system_name

    for key, value in spec.options.items():
        if key not in PACKAGE_OVERRIDE_KEYS:
            continue
        if target_matches(key, package_manager, platform_key):
            return value

    return package_name


def installed_commands(spec: PackageSpec) -> list[str]:
    configured_commands = spec.options.get("command")
    if configured_commands:
        return [command for command in configured_commands.split("|") if command]

    return list[str](dict.fromkeys([spec.brew_name, spec.system_name]))


def already_installed(spec: PackageSpec, runner: CommandRunner) -> str | None:
    for command in installed_commands(spec):
        if runner.command_exists(command):
            return command

    return None


def allowed_package_managers(spec: PackageSpec, platform_key: str) -> list[str]:
    allowed: set[str] = set()

    for manager in PACKAGE_MANAGERS:
        if manager in spec.options:
            allowed.add(manager)

    system = spec.options.get("system")
    if system:
        for entry in system.split("|"):
            entry = entry.strip()
            if not entry:
                continue
            for manager in PACKAGE_MANAGERS:
                if target_matches(entry, manager, platform_key):
                    allowed.add(manager)

    if not spec.raw.startswith("--") and spec.brew_name:
        allowed.add("brew")

    return [manager for manager in PACKAGE_MANAGERS if manager in allowed]


def iter_package_managers(
    runner: CommandRunner, spec: PackageSpec, platform_key: str
):
    for manager in allowed_package_managers(spec, platform_key):
        command = "brew" if manager == "brew" else manager
        if runner.command_exists(command):
            yield manager


def confirm(prompt: str) -> bool:
    reply = input(f"{prompt} [y/N] ")
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
        "pacman": [root_command(["pacman", "-Sy", "--noconfirm", package_name])],
        "apk": [root_command(["apk", "add", package_name])],
    }.get(package_manager)

    if commands is None:
        print(f"Unsupported package manager: {package_manager}", file=sys.stderr)
        return False

    return all(runner.run(command) for command in commands)


def install_package(
    raw_spec: str, runner: CommandRunner, os_release_path: str = "/etc/os-release"
) -> bool:
    return install_package_spec(PackageSpec.parse(raw_spec), runner, os_release_path)


def display_package_name(
    spec: PackageSpec, platform_key: str
) -> str:
    allowed = allowed_package_managers(spec, platform_key)
    if allowed:
        return resolve_package_name(spec, allowed[0], platform_key)
    return spec.brew_name


def install_package_spec(
    spec: PackageSpec, runner: CommandRunner, os_release_path: str = "/etc/os-release"
) -> bool:
    platform_key = detect_platform_key(os_release_path)
    package_name = display_package_name(spec, platform_key)

    installed_command = already_installed(spec, runner)
    if installed_command:
        print(f"{package_name} already installed ({installed_command} found)")
        return True

    package_managers = list[str](iter_package_managers(runner, spec, platform_key))
    if not package_managers:
        print(
            f"No allowed package manager available for {spec.raw}",
            file=sys.stderr,
        )
    else:
        for index, package_manager in enumerate(package_managers):
            manager_package_name = resolve_package_name(
                spec, package_manager, platform_key
            )
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

    cargo_package = spec.options.get("cargo")
    if cargo_package and runner.command_exists("cargo"):
        installed_command = already_installed(spec, runner)
        if installed_command:
            print(f"{package_name} already installed ({installed_command} found)")
            return True
        print(f"Installing {cargo_package} with Cargo")
        if runner.run(["cargo", "install", cargo_package]):
            return True
        print(
            f"Cargo install failed for {cargo_package}, trying fallback installers",
            file=sys.stderr,
        )

    install_script = spec.options.get("script")
    if install_script:
        installed_command = already_installed(spec, runner)
        if installed_command:
            print(f"{package_name} already installed ({installed_command} found)")
            return True
        if runner.dry_run or confirm(
            f"Install {package_name} by downloading and running {install_script}?"
        ):
            return runner.run(
                [f"curl -fsSL {shlex.quote(install_script)} | bash"], shell=True
            )

        print("Installation cancelled.")
        return False

    print(f"No fallback installer available for {spec.raw}", file=sys.stderr)
    return False


def pipe_join(values: list[str] | None) -> str | None:
    if not values:
        return None

    items = [item for value in values for item in value.split("|") if item]
    return "|".join(dict.fromkeys(items)) or None


def manager_flag_values(args: argparse.Namespace) -> dict[str, str | None]:
    return {
        "brew": args.brew,
        "apt-get": args.apt,
        "dnf": args.dnf,
        "yum": args.yum,
        "pacman": args.pacman,
        "apk": args.apk,
    }


def spec_from_args(args: argparse.Namespace) -> PackageSpec | None:
    options: dict[str, str] = {}
    for manager, package in manager_flag_values(args).items():
        if package is not None:
            options[manager] = package

    for key, value in {
        "cargo": args.cargo,
        "script": args.script,
        "command": pipe_join(args.command),
    }.items():
        if value is not None:
            options[key] = value

    if not any(manager in options for manager in PACKAGE_MANAGERS):
        return None

    return PackageSpec.from_options(options)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install packages using allowed package managers, Cargo, or script fallback.",
        epilog=USAGE,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("package_specs", metavar="package-spec", nargs="*")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print install commands without executing them",
    )
    parser.add_argument(
        "--os-release",
        default="/etc/os-release",
        help=argparse.SUPPRESS,
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
        help="command to check before installing; repeat or separate with |",
    )

    args = parser.parse_args(argv)
    has_manager_flag = any(
        package is not None for package in manager_flag_values(args).values()
    )
    if not args.package_specs and not has_manager_flag:
        parser.error(
            "provide at least one package-spec or a package manager flag such as --brew"
        )

    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    runner = CommandRunner(dry_run=args.dry_run)

    package_specs = [PackageSpec.parse(raw_spec) for raw_spec in args.package_specs]
    option_spec = spec_from_args(args)
    if option_spec:
        package_specs.append(option_spec)

    for package_spec in package_specs:
        if not install_package_spec(package_spec, runner, args.os_release):
            return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
