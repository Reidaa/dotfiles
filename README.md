# dotfiles

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Reidaa/dotfiles/main/install.sh | bash
```

This clones the repo to `~/.dotfiles` and runs `init.sh`. Run it again to update.
Set `DOTFILES_DIR` to clone somewhere else. Works on Linux and macOS (Apple Silicon).
Requires `git` and `curl`, plus the packages that [Homebrew needs on Linux](https://docs.brew.sh/Homebrew-on-Linux#requirements).
If Homebrew is missing, it installs Homebrew first. Homebrew's installer needs sudo, so it asks for your password.

## How it works

- `init.sh` adds one line to `~/.zshrc` that sources `zsh/rc.zsh`. Edit `zsh/rc.zsh`, not `~/.zshrc`.
- `cli/brew/install.sh` installs Homebrew if needed, then the CLI tools in `cli/brew/Brewfile`, on Linux and macOS.
- `init.sh` runs `cli/brew/install.sh` first, then every other `cli/*/install.sh`. If one fails, it runs the rest, lists the failures, and exits 1.

## Develop

- `just test` runs the unit tests.
- `just e2e` runs the bootstrap in clean Ubuntu, Fedora and Arch containers. It needs podman or docker, and it tests the committed `HEAD`.
- CI also runs the bootstrap on a macOS runner. That test runs only in CI, because it installs Homebrew packages on the machine.
