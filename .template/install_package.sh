#!/usr/bin/env bash

set -u

usage() {
	cat <<'EOF'
Usage: install_package.sh <package-spec> [<package-spec> ...]

Package spec format:
	brew-package
	brew-package:system-package
	brew-package:system-package,target=package,target=package

Examples:
	install_package.sh ripgrep
	install_package.sh fd:fd-find bat
	install_package.sh tealdeer:tealdeer,funtoo=app-misc/tealdeer,freebsd=sysutils/tealdeer,netbsd=sysutils/tealdeer

The script tries Homebrew first. If brew is unavailable or the install fails,
it infers the system package manager from the current distro and installs the
	mapped package name instead. Override targets can be distro IDs such as
	debian, fedora, arch, freebsd, netbsd, funtoo, opensuse, or manager names
	such as apt-get, dnf, pacman, zypper, pkg, pkgin, port, nix, and emerge.
EOF
}

detect_platform_key() {
	local platform_key
	platform_key=""

	if [ -r /etc/os-release ]; then
		# shellcheck disable=SC1091
		. /etc/os-release
		platform_key="${ID:-}"
	fi

	if [ -z "$platform_key" ]; then
		case "$(uname -s)" in
		Darwin)
			platform_key="macos"
			;;
		FreeBSD)
			platform_key="freebsd"
			;;
		NetBSD)
			platform_key="netbsd"
			;;
		esac
	fi

	case "$platform_key" in
	opensuse-leap | opensuse-tumbleweed)
		platform_key="opensuse"
		;;
	esac

	if [ -n "$platform_key" ]; then
		echo "$platform_key"
		return 0
	fi

	return 1
}

detect_package_manager() {
	local distro_ids platform_key
	distro_ids=""
	platform_key="$(detect_platform_key 2>/dev/null || true)"

	if [ -r /etc/os-release ]; then
		# shellcheck disable=SC1091
		. /etc/os-release
		distro_ids="${ID:-} ${ID_LIKE:-}"
	fi

	case "$platform_key" in
	macos)
		if command -v port >/dev/null 2>&1; then
			echo "port"
			return 0
		fi
		;;
	freebsd)
		if command -v pkg >/dev/null 2>&1; then
			echo "pkg"
			return 0
		fi
		;;
	netbsd)
		if command -v pkgin >/dev/null 2>&1; then
			echo "pkgin"
			return 0
		elif command -v pkg_add >/dev/null 2>&1; then
			echo "pkg_add"
			return 0
		fi
		;;
	esac

	case " ${distro_ids} " in
	*" debian "* | *" ubuntu "* | *" linuxmint "* | *" pop "* | *" elementary "* | *" zorin "* | *" raspbian "* | *" kali "* | *" devuan "*)
		echo "apt-get"
		return 0
		;;
	*" fedora "* | *" rhel "* | *" centos "* | *" rocky "* | *" almalinux "* | *" ol "*)
		if command -v dnf >/dev/null 2>&1; then
			echo "dnf"
		else
			echo "yum"
		fi
		return 0
		;;
	*" arch "* | *" manjaro "* | *" endeavouros "* | *" garuda "* | *" artix "*)
		echo "pacman"
		return 0
		;;
	*" alpine "*)
		echo "apk"
		return 0
		;;
	*" opensuse "* | *" suse "* | *" sles "*)
		echo "zypper"
		return 0
		;;
	*" void "*)
		echo "xbps-install"
		return 0
		;;
	*" gentoo "* | *" funtoo "*)
		echo "emerge"
		return 0
		;;
	*" nixos "*)
		echo "nix"
		return 0
		;;
	*" solus "*)
		echo "eopkg"
		return 0
		;;
	esac

	if command -v apt-get >/dev/null 2>&1; then
		echo "apt-get"
	elif command -v dnf >/dev/null 2>&1; then
		echo "dnf"
	elif command -v yum >/dev/null 2>&1; then
		echo "yum"
	elif command -v pacman >/dev/null 2>&1; then
		echo "pacman"
	elif command -v apk >/dev/null 2>&1; then
		echo "apk"
	elif command -v zypper >/dev/null 2>&1; then
		echo "zypper"
	elif command -v xbps-install >/dev/null 2>&1; then
		echo "xbps-install"
	elif command -v emerge >/dev/null 2>&1; then
		echo "emerge"
	elif command -v nix >/dev/null 2>&1 || command -v nix-env >/dev/null 2>&1; then
		echo "nix"
	elif command -v eopkg >/dev/null 2>&1; then
		echo "eopkg"
	elif command -v pkg >/dev/null 2>&1; then
		echo "pkg"
	elif command -v pkgin >/dev/null 2>&1; then
		echo "pkgin"
	elif command -v pkg_add >/dev/null 2>&1; then
		echo "pkg_add"
	elif command -v port >/dev/null 2>&1; then
		echo "port"
	elif command -v scoop >/dev/null 2>&1; then
		echo "scoop"
	else
		return 1
	fi
}

override_matches_target() {
	local override_key="$1"
	local package_manager="$2"
	local platform_key="$3"
	local normalized_key

	normalized_key="$(printf '%s' "$override_key" | tr '[:upper:]' '[:lower:]')"

	case "$normalized_key" in
	$package_manager | $platform_key)
		return 0
		;;
	brew | homebrew)
		[ "$package_manager" = "brew" ]
		return
		;;
	apt | apt-get | debian | ubuntu | linuxmint | pop | elementary | zorin | raspbian | kali | devuan)
		[ "$package_manager" = "apt-get" ]
		return
		;;
	dnf | fedora)
		[ "$package_manager" = "dnf" ]
		return
		;;
	yum | rhel | centos | rocky | almalinux | ol)
		[ "$package_manager" = "yum" ] || [ "$package_manager" = "dnf" ]
		return
		;;
	arch | manjaro | endeavouros | garuda | artix | pacman)
		[ "$package_manager" = "pacman" ]
		return
		;;
	apk | alpine)
		[ "$package_manager" = "apk" ]
		return
		;;
	zypper | opensuse | suse | sles)
		[ "$package_manager" = "zypper" ]
		return
		;;
	xbps | xbps-install | void)
		[ "$package_manager" = "xbps-install" ]
		return
		;;
	emerge | gentoo | funtoo)
		[ "$package_manager" = "emerge" ]
		return
		;;
	nix | nixos)
		[ "$package_manager" = "nix" ]
		return
		;;
	eopkg | solus)
		[ "$package_manager" = "eopkg" ]
		return
		;;
	pkg | freebsd)
		[ "$package_manager" = "pkg" ]
		return
		;;
	pkgin | pkg_add | netbsd)
		[ "$package_manager" = "pkgin" ] || [ "$package_manager" = "pkg_add" ]
		return
		;;
	port | macports | macos | darwin)
		[ "$package_manager" = "port" ]
		return
		;;
	scoop | windows)
		[ "$package_manager" = "scoop" ]
		return
		;;
	esac

	return 1
}

resolve_package_name() {
	local package_spec="$1"
	local package_manager="$2"
	local platform_key="$3"
	local base_spec package_name override key value
	local -a spec_parts

	IFS=, read -r -a spec_parts <<<"$package_spec"
	base_spec="${spec_parts[0]}"

	if [ "$package_manager" = "brew" ]; then
		package_name="${base_spec%%:*}"
	else
		if [ "$base_spec" = "${base_spec%%:*}" ]; then
			package_name="$base_spec"
		else
			package_name="${base_spec#*:}"
		fi
	fi

	for override in "${spec_parts[@]:1}"; do
		key="${override%%=*}"
		if [ "$override" = "$key" ]; then
			continue
		fi

		value="${override#*=}"
		if override_matches_target "$key" "$package_manager" "$platform_key"; then
			package_name="$value"
			break
		fi
	done

	echo "$package_name"
}

run_as_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

install_with_system_manager() {
	local package_manager="$1"
	local package_name="$2"

	case "$package_manager" in
	apt-get)
		run_as_root apt-get update
		run_as_root apt-get install -y "$package_name"
		;;
	dnf)
		run_as_root dnf install -y "$package_name"
		;;
	yum)
		run_as_root yum install -y "$package_name"
		;;
	pacman)
		run_as_root pacman -Sy --noconfirm "$package_name"
		;;
	apk)
		run_as_root apk add "$package_name"
		;;
	zypper)
		run_as_root zypper install -y "$package_name"
		;;
	xbps-install)
		run_as_root xbps-install -Sy "$package_name"
		;;
	emerge)
		run_as_root emerge --ask=n "$package_name"
		;;
	nix)
		if command -v nix >/dev/null 2>&1; then
			if [[ "$package_name" == *"#"* ]]; then
				nix profile install "$package_name"
			else
				nix profile install "nixpkgs#$package_name"
			fi
		else
			run_as_root nix-env -iA "nixpkgs.${package_name}"
		fi
		;;
	eopkg)
		run_as_root eopkg install -y "$package_name"
		;;
	pkg)
		run_as_root pkg install -y "$package_name"
		;;
	pkgin)
		run_as_root pkgin -y install "$package_name"
		;;
	pkg_add)
		run_as_root pkg_add "$package_name"
		;;
	port)
		run_as_root port install "$package_name"
		;;
	scoop)
		scoop install "$package_name"
		;;
	*)
		echo "Unsupported package manager: $package_manager" >&2
		return 1
		;;
	esac
}

install_package() {
	local package_spec="$1"
	local brew_package_name system_package_name package_manager platform_key

	platform_key="$(detect_platform_key 2>/dev/null || true)"
	brew_package_name="$(resolve_package_name "$package_spec" "brew" "$platform_key")"

	if command -v brew >/dev/null 2>&1; then
		echo "Installing ${brew_package_name} with Homebrew"
		if brew install "$brew_package_name"; then
			return 0
		fi
		echo "Homebrew install failed for ${brew_package_name}, trying the system package manager" >&2
	else
		echo "Homebrew not found, trying the system package manager for ${system_package_name}"
	fi

	if ! package_manager="$(detect_package_manager)"; then
		echo "Could not infer a supported system package manager for ${system_package_name}" >&2
		return 1
	fi

	system_package_name="$(resolve_package_name "$package_spec" "$package_manager" "$platform_key")"

	echo "Installing ${system_package_name} with ${package_manager}"
	install_with_system_manager "$package_manager" "$system_package_name"
}

main() {
	local package_spec

	if [ "$#" -eq 0 ]; then
		usage >&2
		exit 1
	fi

	for package_spec in "$@"; do
		install_package "$package_spec"
	done
}

main "$@"
