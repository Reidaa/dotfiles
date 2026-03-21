if command -v brew >/dev/null 2>&1; then
	brew install starship
elif command -v cargo >/dev/null 2>&1; then
	cargo install starship
else
	echo "Error: Neither Homebrew nor Cargo is available. Please install one of them to proceed."
fi
