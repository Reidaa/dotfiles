# shellcheck shell=bash
# Shell config owned by the dotfiles repo.
# init.sh adds one line to ~/.zshrc that sources this file. Edit this file,
# not ~/.zshrc. Each block checks for its tool first, so a missing tool never
# breaks the shell.
# The file is zsh. It avoids zsh-only syntax where it can, so shellcheck
# (bash mode) can check it.

# Repo root: in a sourced zsh file, $0 is the file path (this is <repo>/zsh/rc.zsh).
dotfiles_dir="${0:A:h:h}"

# my/install.sh puts its scripts in ~/.local/bin.
case ":${PATH}:" in
*":${HOME}/.local/bin:"*) ;;
*) export PATH="${HOME}/.local/bin:${PATH}" ;;
esac

# Homebrew installs the CLI tools (cli/brew/Brewfile). It does not put itself
# on PATH, so load its env first: the blocks below check for its tools.
# HOMEBREW_PREFIX, when set, picks the prefix (cli/brew/install.sh does the
# same); otherwise use the first default prefix that has brew.
if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
	brew_candidates=("${HOMEBREW_PREFIX}/bin/brew")
else
	brew_candidates=(/opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew)
fi
for brew_bin in "${brew_candidates[@]}"; do
	if [[ -x $brew_bin ]]; then
		eval "$("$brew_bin" shellenv)"
		break
	fi
done
unset brew_bin brew_candidates

# mise before the other tools: it puts the tools of a project's mise.toml on
# PATH. `mise activate` also sets PATH at once, so `zsh -i -c` sees them.
if command -v mise >/dev/null 2>&1; then
	eval "$(mise activate zsh)"
fi

if command -v starship >/dev/null 2>&1; then
	eval "$(starship init zsh)"
fi

if command -v atuin >/dev/null 2>&1; then
	eval "$(atuin init zsh)"
fi

if command -v nvim >/dev/null 2>&1; then
	export EDITOR="nvim"
fi

# shellcheck source=alias.sh
source "${dotfiles_dir}/alias.sh"
# shellcheck source=cli/bat/activate.sh
source "${dotfiles_dir}/cli/bat/activate.sh"
# shellcheck source=/dev/null
source "${dotfiles_dir}/cli/claudex/activate.sh"

# Plugins cloned by cli/zsh/install.sh. zsh-syntax-highlighting must load last.
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
	plugin_file="${HOME}/.local/zsh/plugins/${plugin}/${plugin}.zsh"
	# shellcheck source=/dev/null
	[[ -r $plugin_file ]] && source "$plugin_file"
done
unset plugin plugin_file
