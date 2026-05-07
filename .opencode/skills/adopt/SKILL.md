---
name: adopt
description: Apply the garethrhughes/local dotfiles setup to an existing system without a full reinstall. Symlink configs, install missing tools, and bring a machine up to date with the repo — selectively, non-destructively.
compatibility: opencode
---

## What I do

I bring an existing machine into alignment with the `garethrhughes/local` dotfiles repo without running the full interactive `install.sh` from scratch. I assess what is already present, symlink any missing configs, and install only what is absent — leaving existing tools and data untouched.

## When to use me

- Setting up a machine that already has some tools installed
- Re-running setup after the repo has been updated
- Syncing config symlinks without reinstalling applications
- Migrating a partial setup (e.g. only fish + neovim, no apps)

## Repo layout

```
install.sh                — full interactive setup (reference for install logic)
doctor.sh                 — health check (use to verify adoption was successful)
fish/config.fish          → ~/.config/fish/config.fish
fish/fish_plugins         → ~/.config/fish/fish_plugins
fish/fish_variables       → ~/.config/fish/fish_variables
fish/functions/           → ~/.config/fish/functions/
fish/conf.d/              → ~/.config/fish/conf.d/
fish/completions/         → ~/.config/fish/completions/
ghostty/config            → ~/.config/ghostty/config        (macOS)
kitty/kitty.conf          → ~/.config/kitty/kitty.conf      (Linux)
kitty/tab_bar.py          → ~/.config/kitty/tab_bar.py      (Linux)
git/gitconfig             → ~/.gitconfig
starship/starship.toml    → ~/.config/starship.toml
bat/config                → ~/.config/bat/config
```

## Adoption workflow

### 1. Detect OS and existing state

```bash
# Detect OS
[[ "$OSTYPE" == "darwin"* ]] && OS="macos" || OS="linux"

# Check what is already installed
command -v fish starship nvim node npm docker git brew
```

### 2. Run doctor.sh first

Always start by running the health check to understand current state:

```bash
./doctor.sh
```

Collect the full output. Items that `✔ pass` need no action. Focus on `✘` and `⚠`.

### 3. Symlink all config files

Config symlinks are always safe to re-apply (`ln -sfn` overwrites without destroying the target). Back up any unmanaged files first.

```bash
DOTFILES="$PWD"  # must be run from repo root

backup_if_unmanaged() {
    local dst="$1"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        mv "$dst" "${dst}.bak.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Fish
mkdir -p ~/.config/fish
for f in config.fish fish_plugins fish_variables; do
    backup_if_unmanaged ~/.config/fish/$f
    ln -sfn "$DOTFILES/fish/$f" ~/.config/fish/$f
done
for d in functions conf.d completions; do
    backup_if_unmanaged ~/.config/fish/$d
    ln -sfn "$DOTFILES/fish/$d" ~/.config/fish/$d
done

# Starship
backup_if_unmanaged ~/.config/starship.toml
ln -sfn "$DOTFILES/starship/starship.toml" ~/.config/starship.toml

# Bat
mkdir -p ~/.config/bat
backup_if_unmanaged ~/.config/bat/config
ln -sfn "$DOTFILES/bat/config" ~/.config/bat/config

# Git
backup_if_unmanaged ~/.gitconfig
ln -sfn "$DOTFILES/git/gitconfig" ~/.gitconfig

# Terminal (OS-specific)
if [[ "$OS" == "macos" ]]; then
    mkdir -p ~/.config/ghostty
    backup_if_unmanaged ~/.config/ghostty/config
    ln -sfn "$DOTFILES/ghostty/config" ~/.config/ghostty/config
else
    mkdir -p ~/.config/kitty
    backup_if_unmanaged ~/.config/kitty/kitty.conf
    ln -sfn "$DOTFILES/kitty/kitty.conf" ~/.config/kitty/kitty.conf
    ln -sfn "$DOTFILES/kitty/tab_bar.py" ~/.config/kitty/tab_bar.py
fi
```

### 4. Install missing tools (selective)

Only install tools that are absent. Check first, install only if needed.

```bash
# Fish
command -v fish || { [[ "$OS" == "macos" ]] && brew install fish || sudo apt-get install -y fish; }

# Starship
command -v starship || { [[ "$OS" == "macos" ]] && brew install starship || curl -sS https://starship.rs/install.sh | sh -s -- --yes; }

# Neovim
command -v nvim || { [[ "$OS" == "macos" ]] && brew install neovim || sudo add-apt-repository -y ppa:neovim-ppa/unstable && sudo apt-get install -y neovim; }

# bat, fzf, ripgrep, fd
if [[ "$OS" == "macos" ]]; then
    for t in bat fzf ripgrep fd; do brew list $t &>/dev/null || brew install $t; done
else
    for t in bat fzf ripgrep fd-find; do dpkg -s $t &>/dev/null || sudo apt-get install -y $t; done
    command -v fd || ln -sfn $(command -v fdfind) ~/.local/bin/fd
fi

# Git
command -v git || { [[ "$OS" == "macos" ]] && brew install git || sudo apt-get install -y git; }

# nvm + Node LTS
if [[ "$OS" == "macos" ]]; then
    brew list nvm &>/dev/null || brew install nvm
fi
command -v fish && fish -c "fisher list | grep -q nvm.fish || fisher install jorgebucaran/nvm.fish"
command -v fish && fish -c "node --version &>/dev/null || nvm install lts"
```

### 5. Set fish as default shell

```bash
FISH_PATH=$(command -v fish)
if [[ -n "$FISH_PATH" && "$SHELL" != "$FISH_PATH" ]]; then
    grep -qx "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells
    chsh -s "$FISH_PATH"
    echo "Default shell changed — log out and back in to apply"
fi
```

### 6. Install fisher + plugins

```bash
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update"
```

### 7. Neovim setup

```bash
NVIM_SETUP="$HOME/dotfiles/nvim-setup"
[[ -d "$NVIM_SETUP" ]] || git clone https://github.com/garethrhughes/nvim-setup.git "$NVIM_SETUP"
[[ -f "$NVIM_SETUP/install.sh" ]] && bash "$NVIM_SETUP/install.sh" || ln -sfn "$NVIM_SETUP/config/nvim" ~/.config/nvim
```

### 8. Verify

```bash
./doctor.sh
```

All previously failing checks should now pass. Investigate any remaining `✘` using the `doctor` skill.

## Adoption principles

- **Non-destructive** — always back up unmanaged files before symlinking, never delete user data
- **Idempotent** — safe to run multiple times; `ln -sfn` and `brew install` are no-ops if already present
- **Selective** — adopt individual components if only a subset is needed; you do not have to adopt everything
- **Verify last** — always end with `./doctor.sh` to confirm state

## Selective adoption examples

**Only configs, no installs:**
Apply just the symlinks from step 3. Useful when tools are already installed via a system package manager.

**Only fish config:**
```bash
ln -sfn "$PWD/fish/config.fish" ~/.config/fish/config.fish
ln -sfn "$PWD/fish/fish_plugins" ~/.config/fish/fish_plugins
fish -c "fisher update"
```

**Only neovim:**
```bash
git clone https://github.com/garethrhughes/nvim-setup.git ~/dotfiles/nvim-setup
bash ~/dotfiles/nvim-setup/install.sh
```

**Only dotfile configs (no tool installs at all):**
Run step 3 only. Then run `./doctor.sh` — tool checks will warn/fail but config checks should pass.

## Adding a new machine to the repo

If the machine has local config divergences worth keeping:
1. Compare `~/.config/<tool>/config` with `<tool>/config` in the repo
2. Decide which version to keep (usually the repo wins; override if the local version has useful additions)
3. If merging, edit the file in the repo, re-symlink, commit and push
4. Run `./doctor.sh` to confirm

## Constraints

- Always run from the repo root (`cd ~/dotfiles/local`)
- Never `rm` existing config files — always `mv` to a `.bak.*` timestamped backup
- Commit any config changes back to the repo before considering adoption complete
