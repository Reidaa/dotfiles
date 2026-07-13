# Claudex

Run Claude Code through CLIProxyAPI using GPT-5.6 Sol.

## Install

```bash
bash ~/.dotfiles/cli/claudex/install.sh
```

The installer:

- installs CLIProxyAPI with Homebrew when needed;
- creates `~/.config/claudex/config.zsh` with mode `0600`;
- sources `activate.sh` from `~/.zshrc`;
- leaves existing user configuration untouched.

## Configure

1. Connect CLIProxyAPI to Codex if it is not connected yet:

   ```bash
   cliproxyapi -codex-login
   ```

2. Generate a local proxy key:

   ```bash
   openssl rand -hex 32
   ```

3. Open the CLIProxyAPI management page:

   ```text
   http://127.0.0.1:8317/management.html?safe-mode=configure
   ```

   Replace every `your-api-key-*` template value with the generated key. Set
   the proxy host to `127.0.0.1` so it is only reachable from this machine.

4. Put the same generated key in `~/.config/claudex/config.zsh`:

   ```zsh
   export CLAUDEX_API_KEY="your-generated-key"
   ```

5. Start or restart the proxy and reload the shell:

   ```bash
   brew services restart cliproxyapi
   source ~/.zshrc
   ```

6. Launch Claude Code with GPT-5.6 Sol:

   ```bash
   claudex
   ```

Additional Claude Code arguments are forwarded, for example:

```bash
claudex --continue
```

Model, proxy URL, subagent model, concurrency, effort, and tool-search defaults
can all be changed in `~/.config/claudex/config.zsh`.
