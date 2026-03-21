# Check whether a string exists in a file.
# Usage: string_in_file "needle" /path/to/file
string_in_file() {
	grep -Fq -- "$1" "$2"
}

if [ ! -d "${HOME}/.local/zsh/plugins" ]; then
	mkdir -p ${HOME}/.local/zsh/plugins
fi

if [ ! -d "${HOME}/.local/zsh/plugins/zsh-autosuggestions" ]; then
	git clone https://github.com/zsh-users/zsh-autosuggestions ${HOME}/.local/zsh/plugins/zsh-autosuggestions
fi

if [ ! -d "${HOME}/.local/zsh/plugins/zsh-syntax-highlighting" ]; then
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${HOME}/.local/zsh/plugins/zsh-syntax-highlighting
fi

if string_in_file "zsh-autosuggestions.zsh" "${HOME}/.zshrc"; then
	echo "zsh-autosuggestions already sourced in .zshrc"
else
	echo "source ${HOME}/.local/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >>"${HOME}/.zshrc"
fi

if string_in_file "zsh-syntax-highlighting.zsh" "${HOME}/.zshrc"; then
	echo "zsh-syntax-highlighting already sourced in .zshrc"
else
	echo "source ${HOME}/.local/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >>"${HOME}/.zshrc"
fi
