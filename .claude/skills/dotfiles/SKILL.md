---
name: dotfiles
description: >
  Helps manage a dotfiles bare git repository with work-tree at $HOME.
  Use this skill whenever the user wants to track a new config file, add a tool's
  config to dotfiles, decide what to track vs. ignore, move a config to an
  XDG-compliant location (~/.config/), fix accidentally staged files, or untrack
  a file that was already pushed. Trigger for phrases like "add X to dotfiles",
  "track my X config", "should I track X", "move X config to .config",
  "I accidentally staged", or any dotfiles repo question.
---

## Setup assumed

The user manages dotfiles using a bare git repo:

- Git dir: `~/.dotfiles/`
- Work tree: `$HOME`
- Alias: `dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'`
- Gitignore: `~/.gitignore` (repo root since work-tree is `$HOME`)

---

## Adding a new tool's config

### 1. Find the config
Check where the tool stores config — common locations: `~/`, `~/.config/<tool>/`, `~/.local/share/<tool>/`.

### 2. Suggest XDG migration if the config is in `~/`
Many tools support relocation via an env var. If supported, suggest moving the file to `~/.config/<tool>/` and setting the env var in `~/.zshenv` or `~/.config/zsh/.zshrc`.

Common patterns:

| Tool | Mechanism |
|------|-----------|
| zsh | `ZDOTDIR` (note: `~/.zshenv` must stay in `~/`) |
| npm | `NPM_CONFIG_USERCONFIG` |
| ripgrep | `RIPGREP_CONFIG_PATH` |
| wget | `WGETRC` |
| most tools | `XDG_CONFIG_HOME=$HOME/.config` |

After moving, verify the tool still works before committing.

### 3. Decide what to track vs. ignore

**Track** — portable config you've intentionally edited:
- Config files, themes, keybindings, plugin lists

**Don't track** — runtime/generated/machine-specific:
- Cache (`*.cache`, `*.zwc`, compiled artifacts)
- History files (`*_history`, `*.log`)
- Session, lock, or credential files
- Auto-generated files recreated on startup

If there are generated files alongside tracked ones, add them to `~/.gitignore` before staging.

### 4. Stage and commit

```sh
dotfiles add <file(s)>
dotfiles commit -m "<tool>: track config"
```

---

## Common recovery scenarios

### Accidental `dotfiles add .`
Unstage everything:
```sh
dotfiles restore --staged -- .
```
Then add only the intended files.

### File already pushed that shouldn't be tracked
```sh
dotfiles rm --cached -- <file>
# add to ~/.gitignore
dotfiles add ~/.gitignore
dotfiles commit -m "untrack <file>"
dotfiles push
```
Note: the file still exists in git history. If it contained sensitive data, a history rewrite is needed.

### Check what's currently tracked
```sh
dotfiles ls-files
```

---

## .gitignore hygiene

Always prefer `~/.gitignore` over `~/.dotfiles/info/exclude` — it's trackable in the repo itself and portable across machines.

Add ignores before staging to avoid accidentally committing generated files. Common entries:

```
# zsh
.config/zsh/.zcompdump*
.config/zsh/.zsh_sessions/
.config/zsh/.zsh_history

# claude
.claude/projects/
.claude/sessions/
.claude/history.jsonl
.claude/cache/
```
