# dotfiles

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Reidaa/dotfiles/main/install.sh | bash
```

This clones the repo to `~/.dotfiles` and runs `init.sh`. Run it again to update.
Set `DOTFILES_DIR` to clone somewhere else. Works on Linux and macOS (Apple Silicon).
Requires `git`, `curl` and [Homebrew](https://brew.sh). Install Homebrew first: if it is missing, the installer reports it and exits without changing anything.
With Homebrew installed, the installer needs no sudo.

## How it works

- `init.sh` adds one line to `~/.zshrc` that sources `zsh/rc.zsh`. Edit `zsh/rc.zsh`, not `~/.zshrc`.
- `cli/brew/install.sh` installs the CLI tools in `cli/brew/Brewfile` with Homebrew, on Linux and macOS.
- `init.sh` runs `cli/brew/install.sh` first, then every other `cli/*/install.sh`. If one fails, it runs the rest, lists the failures, and exits 1.

## Develop

- `just test` runs the unit tests.
- `just e2e` runs the bootstrap in clean Ubuntu, Fedora and Arch containers. Each container installs Homebrew first, as machine setup. It needs podman or docker, and it tests the committed `HEAD`.
- CI also runs the bootstrap on a macOS runner. That test runs only in CI, because it installs Homebrew packages on the machine.
