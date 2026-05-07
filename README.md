# local

Dotfiles and machine setup for macOS and Kubuntu.

## Quick Start

```bash
git clone git@github.com:garethrhughes/local.git ~/dotfiles/local
cd ~/dotfiles/local
./install.sh
```

Each component is **optional** — the installer will prompt you for each one.

## Scripts

| Script | Purpose |
|--------|---------|
| `install.sh` | Interactive setup — installs tools and symlinks config files |
| `doctor.sh` | Health check — verifies all tools and symlinks are in place |

```bash
./doctor.sh   # check for issues after install
```

## Components

### Shell
- **Fish** — default shell with fisher plugin manager
- **Starship** — cross-shell prompt

### Fonts
- **JetBrainsMono Nerd Font** — used by terminal and Neovim

### Terminal
- **Ghostty** (macOS) — with config at `ghostty/config`
- **Kitty** (Linux) — with config at `kitty/kitty.conf`
- **Scroll Reverser** (macOS)

### Editors
- **Neovim** — via [garethrhughes/nvim-setup](https://github.com/garethrhughes/nvim-setup)
- **VS Code** + GitHub Copilot extension
- **Sublime Text**
- **Sublime Merge**

### CLI Tools
- `bat` · `fzf` · `ripgrep` · `fd`
- `git` — with config symlinked from `git/gitconfig`
- `asdf` — version manager
- `node` — via asdf
- `docker` — Docker Engine (Linux) / Docker Desktop (macOS) + Compose v2
- `granted` — AWS assume
- `pokemon-colorscripts` — fish greeting
- `opencode` — AI coding agent

### Apps
- Firefox · Bitwarden · Spotify · Discord

> **Bitwarden browser extensions** — links are printed during install:
> Firefox · Chrome · Safari (macOS)

### Linux (Kubuntu)
- Snap is **disabled** during setup (Mozilla PPA used for Firefox instead)

## Config Layout

```
bat/          → ~/.config/bat/
fish/         → ~/.config/fish/
ghostty/      → ~/.config/ghostty/   (macOS)
kitty/        → ~/.config/kitty/     (Linux)
git/          → ~/.gitconfig
starship/     → ~/.config/starship.toml
```

## Requirements

- macOS: Homebrew (installed automatically if missing)
- Linux: `sudo` access, Kubuntu/Ubuntu-based distro
