---
name: doctor
description: Diagnose and fix issues found by doctor.sh in the garethrhughes/local dotfiles repo. Run the health check, interpret failures and warnings, then repair them by patching install.sh, doctor.sh, or running targeted fix commands.
compatibility: opencode
---

## What I do

I run `./doctor.sh`, read every failure (`✘`) and warning (`⚠`), then fix each issue — either by running a targeted shell command, patching `install.sh` or `doctor.sh`, or guiding the user through a manual step that cannot be scripted.

## Repo layout

```
install.sh       — interactive setup script (setup_* functions, one per component)
doctor.sh        — health check script (check_* functions, one per component)
fish/            → ~/.config/fish/
ghostty/         → ~/.config/ghostty/         (macOS)
kitty/           → ~/.config/kitty/           (Linux)
git/gitconfig    → ~/.gitconfig
starship/        → ~/.config/starship.toml
bat/             → ~/.config/bat/
```

## install.sh structure

Each component has a `setup_<name>()` function. The interactive menu is built from the `items=()` array. Execution is dispatched at the bottom of `main()` via `[[ "${SELECTED[key]:-0}" == "1" ]] && setup_<name>`.

Key `setup_*` functions:
- `setup_fonts` — JetBrainsMono Nerd Font (brew cask / nerd-fonts release tarball)
- `setup_fish` — installs fish, sets default shell via `chsh`, symlinks config
- `setup_terminal` — Ghostty (macOS) / Kitty (Linux) + Scroll Reverser
- `setup_starship` — installs starship, symlinks `starship/starship.toml`
- `setup_neovim` — installs neovim, clones garethrhughes/nvim-setup, runs its install.sh
- `setup_nvm` — nvm (brew/nvm-sh), installs Node LTS via nvm.fish
- `setup_cli_tools` — bat, fzf, ripgrep, fd + bat config symlink
- `setup_git` — installs git, symlinks `git/gitconfig` → `~/.gitconfig`
- `setup_docker` — Docker Desktop (macOS) / Docker Engine + Compose v2 (Linux)
- `setup_granted` — AWS assume tool
- `setup_pokemon` — pokemon-colorscripts fish greeting
- `setup_nordvpn` — NordVPN (brew cask / nordcdn install script)
- `setup_opencode` — OpenCode CLI
- `setup_github_copilot` — gh CLI + gh-copilot extension + VS Code extensions
- `setup_claude` — Claude Desktop (macOS brew cask) / Claude Code npm (Linux)
- `setup_vscode`, `setup_sublime_text`, `setup_sublime_merge`, `setup_firefox`, `setup_bitwarden`, `setup_spotify`, `setup_discord`

## doctor.sh structure

Each `check_*` function prints `✔ pass`, `⚠ warn`, or `✘ fail` lines then increments counters. Uses `set -uo pipefail` (no `-e`) and `((N++)) || true` to avoid exit-on-zero.

Key `check_*` functions and what they verify:
- `check_shell` — fish binary on PATH, fish is `$SHELL`
- `check_fonts` — JetBrainsMono installed (brew cask list / fc-list)
- `check_terminal` — ghostty config (macOS) or kitty config (Linux), Scroll Reverser
- `check_prompt` — starship binary + `~/.config/starship.toml`
- `check_fish_config` — config.fish, fish_plugins, fisher binary, fisher plugin list
- `check_nvim` — nvim binary, `~/.config/nvim`, nvim-setup repo at `~/dotfiles/nvim-setup`
- `check_nvm` — nvm.fish fisher plugin, active node version, `~/.nvm` (Linux), node/npm on PATH
- `check_cli_tools` — bat, fzf, rg, fd, pokemon-colorscripts, bat config file
- `check_git` — git binary, `~/.gitconfig`, user.name, user.email
- `check_docker` — docker binary + version, daemon running, Compose v2, docker group (Linux)
- `check_granted` — granted + assume on PATH
- `check_apps` — app binaries / .app bundles for Sublime Text, Merge, VS Code, Firefox, Bitwarden, Spotify, Discord
- `check_opencode` — opencode binary
- `check_nordvpn` — nordvpn binary, connection status, nordvpn group (Linux)
- `check_vscode_extensions` — GitHub.copilot, GitHub.copilot-chat
- `check_snap_disabled` — snap removed, no-snap.pref present (Linux only)
- `check_dotfiles_symlinks` — config files present at their target paths

## Workflow

1. **Run the health check**
   ```bash
   ./doctor.sh
   ```
2. **Triage output** — collect all `✘` (failures) and `⚠` (warnings) lines.
3. **For each issue**, choose the appropriate fix strategy:

### Fix strategies

| Issue type | Strategy |
|---|---|
| Binary not found | Run the relevant `setup_*` function body manually, or call `./install.sh` and select only that component |
| Broken/missing symlink | Re-run `symlink <src> <dst>` — create the dir, `ln -sfn` |
| Fisher plugin missing | `fish -c "fisher install <plugin>"` |
| Docker daemon not running | macOS: open Docker.app; Linux: `sudo systemctl start docker` |
| User not in group (docker/nordvpn) | `sudo usermod -aG <group> $USER` then log out/in |
| git identity not set | `git config --global user.name "..."` / `git config --global user.email "..."` |
| Fish not default shell | `chsh -s $(which fish)` after ensuring fish is in `/etc/shells` |
| VS Code extension missing | `code --install-extension <ext>` |
| Snap still active (Linux) | Run `disable_snap` from install.sh or manually purge + pin |
| Node not active (nvm.fish) | `fish -c "nvm install lts && nvm use lts"` |

4. **If the fix requires a script change** (e.g. a check is wrong, a version is stale, a new component needs adding):
   - Edit the relevant `setup_*` or `check_*` function in `install.sh` / `doctor.sh`
   - Verify with `bash -n install.sh && bash -n doctor.sh`
   - Re-run `./doctor.sh` to confirm the fix

5. **Commit when clean**
   ```bash
   git add -A && git commit -m "fix: resolve doctor.sh issues" && git push origin main
   ```

## Common fixes

### Broken dotfile symlink
```bash
# Example: starship.toml missing
ln -sfn "$PWD/starship/starship.toml" "$HOME/.config/starship.toml"
```

### Fisher plugin not installed
```bash
fish -c "fisher install jorgebucaran/nvm.fish"
```

### Node LTS not set
```bash
fish -c "nvm install lts && nvm use lts"
```

### Font not installed (Linux)
Re-run `setup_fonts` logic: download latest JetBrainsMono from nerd-fonts releases, extract to `~/.local/share/fonts`, run `fc-cache -fv`.

### doctor.sh false positive / incorrect check
Edit the `check_*` function. Common patterns:
- Wrong binary name → update `check_cmd` argument
- App bundle name mismatch (macOS) → update the `apps=()` array in `check_apps`
- Missing check for a new component → add a new `check_*` function and call it in `main()`

## Constraints

- Always run `bash -n` on any modified script before applying or committing
- Never use `set -e` in doctor.sh — checks must not abort on failure
- Always use `((N++)) || true` for counter increments in doctor.sh
- Symlinks in install.sh use `ln -sfn` (force, no-dereference) — safe to re-run
