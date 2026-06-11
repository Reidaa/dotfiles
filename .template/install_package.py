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
Package spec format:
  brew-package
  brew-package:system-package
  brew-package:system-package,target=package,target=package
  brew-package:system-package,command=cmd|cmd,system=manager|manager,cargo=crate,script=url

Examples:
  install_package.py ripgrep
  install_package.py 'fd:fd-find,command=fd|fdfind' bat
  install_package.py 'television:television,command=tv|television,system=pacman,cargo=television,script=https://alexpasmantier.github.io/television/install.sh'

The script tries Homebrew first. If brew is unavailable or the install fails,
it infers a supported system package manager from the current distro and
installs the mapped package name instead. Supported system package managers are
apt-get, dnf, yum, pacman, and apk. Use system=manager|manager to limit system
package managers for packages that are not widely packaged. Use cargo=crate or
script=url as fallbacks. Use command=cmd|cmd to skip installation when any of
the listed commands already exists.
"""


SUPPORTED_MANAGERS = ("apt-get", "dnf", "yum", "pacman", "apk")

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

DISTRO_MANAGER_ALIASES = (
    ("apt-get", TARGET_ALIASES["apt-get"]),
    ("dnf", {"fedora"}),
    ("yum", {"rhel", "centos", "rocky", "almalinux", "ol"}),
    ("pacman", TARGET_ALIASES["pacman"]),
    ("apk", TARGET_ALIASES["apk"]),
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

        return cls(raw=raw, brew_name=brew_name, system_name=system_name, options=options)


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

        return subprocess.run(command[0] if shell else command, shell=shell).returncode == 0


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


def detect_package_manager(
    runner: CommandRunner, os_release_path: str = "/etc/os-release"
) -> str | None:
    os_release = read_os_release(os_release_path)
    distro_ids = {
        distro_id.lower()
        for value in (os_release.get("ID", ""), os_release.get("ID_LIKE", ""))
        for distro_id in value.split()
        if distro_id
    }

    for manager, aliases in DISTRO_MANAGER_ALIASES:
        if distro_ids & aliases:
            if manager == "dnf" and not runner.command_exists("dnf"):
                return "yum"
            return manager

    for manager in SUPPORTED_MANAGERS:
        if runner.command_exists(manager):
            return manager

    return None


def target_matches(target: str, package_manager: str, platform_key: str) -> bool:
    normalized_target = target.lower()
    if normalized_target in {package_manager, platform_key}:
        return True
    if normalized_target in {"brew", "homebrew"}:
        return package_manager == "brew"

    aliases = TARGET_ALIASES.get(package_manager, set())
    return normalized_target in aliases


def resolve_package_name(
    spec: PackageSpec, package_manager: str, platform_key: str
) -> str:
    package_name = spec.brew_name if package_manager == "brew" else spec.system_name

    for key, value in spec.options.items():
        if target_matches(key, package_manager, platform_key):
            return value

    return package_name


def installed_commands(spec: PackageSpec) -> list[str]:
    configured_commands = spec.options.get("command")
    if configured_commands:
        return [command for command in configured_commands.split("|") if command]

    return list(dict.fromkeys([spec.brew_name, spec.system_name]))


def already_installed(spec: PackageSpec, runner: CommandRunner) -> str | None:
    for command in installed_commands(spec):
        if runner.command_exists(command):
            return command

    return None


def system_manager_allowed(
    spec: PackageSpec, package_manager: str, platform_key: str
) -> bool:
    allowed = spec.options.get("system")
    if not allowed:
        return True

    return any(
        target_matches(manager, package_manager, platform_key)
        for manager in allowed.split("|")
    )


def confirm(prompt: str) -> bool:
    reply = input(f"{prompt} [y/N] ")
    return reply.lower() in {"y", "yes"}


def root_command(command: list[str]) -> list[str]:
    if os.geteuid() == 0:
        return command
    return ["sudo", *command]


def install_with_system_manager(
    runner: CommandRunner, package_manager: str, package_name: str
) -> bool:
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
    spec = PackageSpec.parse(raw_spec)
    platform_key = detect_platform_key(os_release_path)
    brew_package_name = resolve_package_name(spec, "brew", platform_key)

    installed_command = already_installed(spec, runner)
    if installed_command:
        print(f"{brew_package_name} already installed ({installed_command} found)")
        return True

    if runner.command_exists("brew"):
        print(f"Installing {brew_package_name} with Homebrew")
        if runner.run(["brew", "install", brew_package_name]):
            return True
        print(
            f"Homebrew install failed for {brew_package_name}, trying the system package manager",
            file=sys.stderr,
        )
    else:
        print(f"Homebrew not found, trying the system package manager for {raw_spec}")

    package_manager = detect_package_manager(runner, os_release_path)
    if package_manager is None:
        print(
            f"Could not infer a supported system package manager for {raw_spec}",
            file=sys.stderr,
        )
    elif system_manager_allowed(spec, package_manager, platform_key):
        system_package_name = resolve_package_name(spec, package_manager, platform_key)
        print(f"Installing {system_package_name} with {package_manager}")
        if install_with_system_manager(runner, package_manager, system_package_name):
            return True
        print(
            f"{package_manager} install failed for {system_package_name}, trying fallback installers",
            file=sys.stderr,
        )
    else:
        print(
            f"{raw_spec} is not configured for {package_manager}, trying fallback installers",
            file=sys.stderr,
        )

    cargo_package = spec.options.get("cargo")
    if cargo_package and runner.command_exists("cargo"):
        installed_command = already_installed(spec, runner)
        if installed_command:
            print(f"{brew_package_name} already installed ({installed_command} found)")
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
            print(f"{brew_package_name} already installed ({installed_command} found)")
            return True
        if runner.dry_run or confirm(
            f"Install {brew_package_name} by downloading and running {install_script}?"
        ):
            return runner.run([f"curl -fsSL {shlex.quote(install_script)} | bash"], shell=True)

        print("Installation cancelled.")
        return False

    print(f"No fallback installer available for {raw_spec}", file=sys.stderr)
    return False


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install packages using Homebrew, a supported system manager, Cargo, or script fallback.",
        epilog=USAGE,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("package_specs", metavar="package-spec", nargs="+")
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
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    runner = CommandRunner(dry_run=args.dry_run)

    for package_spec in args.package_specs:
        if not install_package(package_spec, runner, args.os_release):
            return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
