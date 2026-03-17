if [ ! -d "${HOME}/.local/zsh/plugins" ]; then
    mkdir -p ${HOME}/.local/zsh/plugins
fi

if [ ! -d "${HOME}/.local/zsh/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${HOME}/.local/zsh/plugins/zsh-autosuggestions
fi

if [ ! -d "${HOME}/.local/zsh/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${HOME}/.local/zsh/plugins/zsh-syntax-highlighting
fi
