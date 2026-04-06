# Dotfiles

Bare git repository managing config files with work tree at `$HOME`.

```sh
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

## Conventions

### XDG
- Config files go in `~/.config/<tool>/` where possible
- Use tool-specific env vars to relocate (e.g. `ZDOTDIR`, `NPM_CONFIG_USERCONFIG`, `RIPGREP_CONFIG_PATH`)
- `~/.zshenv` must stay in `~/` — zsh hard-codes it; all other zsh config is in `~/.config/zsh/`

### What to track
**Track:** config files you've manually edited — themes, keybindings, plugin lists

**Don't track:**
- Cache and compiled files (`*.cache`, `*.zwc`)
- History files
- Session/lock files
- Credentials or tokens (e.g. `.databrickscfg`)
- Auto-generated files recreated on startup (e.g. `.oh-my-zsh/`)

### .gitignore
Always use `~/.gitignore` (not `~/.dotfiles/info/exclude`) — it's trackable and portable.

Add ignores *before* staging to avoid accidentally committing generated files.

### Commits
```
<tool>: track config
<tool>: move config to ~/.config/<tool>/
gitignore: add <tool>
```
