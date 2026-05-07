#!/usr/bin/env bash
# install.sh — Interactive setup for macOS (Homebrew) and Kubuntu (apt)
set -euo pipefail

# ─── Colours ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}${BOLD}[ OK ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}${BOLD}[ERR ]${RESET}  $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${CYAN}  $*${RESET}"; \
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }

# ─── Detect OS ──────────────────────────────────────────────────────────────
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="linux"
        DISTRO="${ID:-unknown}"
    else
        error "Unsupported OS"; exit 1
    fi
}

# ─── Helpers ────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

prompt_yn() {
    # $1 = question, $2 = default (y/n)
    local default="${2:-y}"
    local prompt
    if [[ "$default" == "y" ]]; then prompt="[Y/n]"; else prompt="[y/N]"; fi
    read -r -p "$(echo -e "${BOLD}$1 ${prompt}${RESET} ")" ans
    ans="${ans:-$default}"
    [[ "$ans" =~ ^[Yy] ]]
}

symlink() {
    # $1 = source (in dotfiles), $2 = target (~/.config/...)
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        local bak="${dst}.bak.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up existing $dst → $bak"
        mv "$dst" "$bak"
    fi
    ln -sfn "$src" "$dst"
    ok "Linked $dst → $src"
}

brew_install() {
    local pkg="$1"
    if brew list --formula "$pkg" &>/dev/null 2>&1; then
        ok "$pkg already installed"
    else
        info "Installing $pkg via brew"
        brew install "$pkg"
    fi
}

brew_cask_install() {
    local pkg="$1"
    if brew list --cask "$pkg" &>/dev/null 2>&1; then
        ok "$pkg already installed"
    else
        info "Installing $pkg via brew cask"
        brew install --cask "$pkg"
    fi
}

apt_install() {
    local pkg="$1"
    if dpkg -s "$pkg" &>/dev/null 2>&1; then
        ok "$pkg already installed"
    else
        info "Installing $pkg via apt"
        sudo apt-get install -y "$pkg"
    fi
}

command_exists() { command -v "$1" &>/dev/null; }

# ─── OS Bootstrap ────────────────────────────────────────────────────────────
setup_macos_bootstrap() {
    header "macOS Bootstrap"
    if ! command_exists brew; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        ok "Homebrew already installed"
    fi
}

setup_linux_bootstrap() {
    header "Linux Bootstrap"
    info "Updating apt..."
    sudo apt-get update -qq
}

# ─── Disable Snap (Kubuntu) ──────────────────────────────────────────────────
disable_snap() {
    if [[ "$OS" != "linux" ]]; then return; fi
    header "Disable Snap"
    if ! command_exists snap; then
        ok "Snap not installed, nothing to do"
        return
    fi
    warn "This will remove snapd and all snap packages."
    if prompt_yn "Disable and remove snap?" y; then
        # Remove snap packages
        snap list 2>/dev/null | awk 'NR>1{print $1}' | while read -r pkg; do
            sudo snap remove --purge "$pkg" 2>/dev/null || true
        done
        sudo systemctl stop snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true
        sudo apt-get purge -y snapd
        sudo apt-mark hold snapd
        # Prevent apt from reinstalling snap
        sudo tee /etc/apt/preferences.d/no-snap.pref > /dev/null <<'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
        ok "Snap disabled and pinned to prevent reinstall"
    fi
}

# ─── Fish Shell ───────────────────────────────────────────────────────────────
setup_fish() {
    header "Fish Shell"
    if [[ "$OS" == "macos" ]]; then
        brew_install fish
    else
        apt_install fish
    fi

    # Set as default shell
    FISH_PATH="$(command -v fish)"
    if [[ "$SHELL" != "$FISH_PATH" ]]; then
        if prompt_yn "Set fish as default shell?" y; then
            if ! grep -q "$FISH_PATH" /etc/shells; then
                echo "$FISH_PATH" | sudo tee -a /etc/shells
            fi
            chsh -s "$FISH_PATH"
            ok "Default shell set to fish"
        fi
    else
        ok "Fish is already the default shell"
    fi

    # Symlink fish config
    symlink "$DOTFILES_DIR/fish/config.fish"   "$HOME/.config/fish/config.fish"
    symlink "$DOTFILES_DIR/fish/fish_plugins"  "$HOME/.config/fish/fish_plugins"
    symlink "$DOTFILES_DIR/fish/fish_variables" "$HOME/.config/fish/fish_variables"

    # Copy functions and conf.d (symlink the whole dirs)
    symlink "$DOTFILES_DIR/fish/functions"     "$HOME/.config/fish/functions"
    symlink "$DOTFILES_DIR/fish/conf.d"        "$HOME/.config/fish/conf.d"
    symlink "$DOTFILES_DIR/fish/completions"   "$HOME/.config/fish/completions"

    # Install fisher + plugins
    if command_exists fish; then
        info "Installing Fisher plugins..."
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update" 2>/dev/null || \
            warn "Fisher install failed — run 'fisher update' manually in fish"
        ok "Fisher plugins installed"
    fi
}

# ─── Terminal ─────────────────────────────────────────────────────────────────
setup_terminal() {
    header "Terminal Emulator"
    if [[ "$OS" == "macos" ]]; then
        info "Installing Ghostty (macOS)"
        brew_cask_install ghostty
        symlink "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

        info "Installing Scroll Reverser (macOS)"
        if ! brew list --cask scroll-reverser &>/dev/null 2>&1; then
            brew_cask_install scroll-reverser
        fi
    else
        info "Installing Kitty (Linux)"
        if ! command_exists kitty; then
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
        else
            ok "Kitty already installed"
        fi
        mkdir -p "$HOME/.config/kitty"
        symlink "$DOTFILES_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
        symlink "$DOTFILES_DIR/kitty/tab_bar.py"  "$HOME/.config/kitty/tab_bar.py"

        # Init kitty-themes submodule
        if [[ ! -f "$DOTFILES_DIR/kitty/kitty-themes/themes/Chalk.conf" ]]; then
            info "Initialising kitty-themes submodule..."
            git -C "$DOTFILES_DIR" submodule update --init --recursive
        fi
        symlink "$DOTFILES_DIR/kitty/kitty-themes/themes/Chalk.conf" \
                "$DOTFILES_DIR/kitty/theme.conf"
    fi
}

# ─── Starship ────────────────────────────────────────────────────────────────
setup_starship() {
    header "Starship Prompt"
    if [[ "$OS" == "macos" ]]; then
        brew_install starship
    else
        if ! command_exists starship; then
            curl -sS https://starship.rs/install.sh | sh -s -- --yes
        else
            ok "Starship already installed"
        fi
    fi
    symlink "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
}

# ─── Neovim ──────────────────────────────────────────────────────────────────
setup_neovim() {
    header "Neovim"
    if [[ "$OS" == "macos" ]]; then
        brew_install neovim
    else
        # Use latest from PPA / appimage for Kubuntu
        if ! command_exists nvim; then
            sudo add-apt-repository -y ppa:neovim-ppa/unstable 2>/dev/null || true
            sudo apt-get update -qq
            apt_install neovim
        else
            ok "Neovim already installed"
        fi
    fi

    NVIM_SETUP_DIR="$HOME/dotfiles/nvim-setup"
    if [[ ! -d "$NVIM_SETUP_DIR" ]]; then
        info "Cloning nvim-setup..."
        git clone https://github.com/garethrhughes/nvim-setup.git "$NVIM_SETUP_DIR"
    else
        ok "nvim-setup repo already cloned at $NVIM_SETUP_DIR"
    fi

    if [[ -f "$NVIM_SETUP_DIR/install.sh" ]]; then
        info "Running nvim-setup install.sh..."
        bash "$NVIM_SETUP_DIR/install.sh"
    else
        warn "nvim-setup has no install.sh — symlinking config manually"
        symlink "$NVIM_SETUP_DIR/config/nvim" "$HOME/.config/nvim"
    fi
}

# ─── ASDF ────────────────────────────────────────────────────────────────────
setup_asdf() {
    header "asdf Version Manager"
    if [[ "$OS" == "macos" ]]; then
        brew_install asdf
    else
        if [[ ! -d "$HOME/.asdf" ]]; then
            info "Installing asdf..."
            git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0
        else
            ok "asdf already installed"
        fi
    fi
}

# ─── Node.js (via asdf) ──────────────────────────────────────────────────────
setup_nodejs() {
    header "Node.js (via asdf)"
    setup_asdf

    # Ensure asdf on PATH for this script
    if [[ "$OS" == "linux" && -f "$HOME/.asdf/asdf.sh" ]]; then
        # shellcheck disable=SC1091
        source "$HOME/.asdf/asdf.sh"
    fi

    if ! command_exists asdf; then
        warn "asdf not found on PATH — skipping Node install. Re-run after restarting shell."
        return
    fi

    if ! asdf plugin list | grep -q nodejs; then
        info "Adding asdf nodejs plugin..."
        asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    else
        ok "asdf nodejs plugin already added"
    fi

    local node_version
    node_version=$(asdf list nodejs 2>/dev/null | grep -v '^$' | tail -1 | tr -d ' *' || true)

    if [[ -z "$node_version" ]]; then
        info "Installing latest Node.js LTS via asdf..."
        asdf install nodejs latest
        asdf global nodejs latest
    else
        ok "Node.js $node_version already installed via asdf"
    fi
}

# ─── Core CLI tools ──────────────────────────────────────────────────────────
setup_cli_tools() {
    header "Core CLI Tools"
    local tools_brew=(bat fzf ripgrep fd)
    local tools_apt=(bat fzf ripgrep fd-find)

    if [[ "$OS" == "macos" ]]; then
        for t in "${tools_brew[@]}"; do brew_install "$t"; done
    else
        for t in "${tools_apt[@]}"; do apt_install "$t"; done
        # fd-find installs as fdfind on Debian/Ubuntu
        if command_exists fdfind && ! command_exists fd; then
            mkdir -p "$HOME/.local/bin"
            ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
            ok "Linked fdfind → ~/.local/bin/fd"
        fi
    fi

    symlink "$DOTFILES_DIR/bat/config" "$HOME/.config/bat/config"
}

# ─── Granted ─────────────────────────────────────────────────────────────────
setup_granted() {
    header "Granted (AWS)"
    if [[ "$OS" == "macos" ]]; then
        if ! command_exists granted; then
            brew_install common-fate/granted/granted
        else
            ok "Granted already installed"
        fi
    else
        if ! command_exists granted; then
            info "Downloading Granted for Linux..."
            local version
            version=$(curl -s https://api.github.com/repos/common-fate/granted/releases/latest \
                | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
            local arch
            arch=$(uname -m); [[ "$arch" == "x86_64" ]] && arch="x86_64" || arch="arm64"
            local tmpdir; tmpdir=$(mktemp -d)
            curl -fsSL "https://releases.commonfate.io/granted/v${version}/granted_${version}_linux_${arch}.tar.gz" \
                -o "$tmpdir/granted.tar.gz"
            tar -xzf "$tmpdir/granted.tar.gz" -C "$tmpdir"
            sudo mv "$tmpdir/granted" /usr/local/bin/
            sudo mv "$tmpdir/assume" /usr/local/bin/
            rm -rf "$tmpdir"
            ok "Granted installed"
        else
            ok "Granted already installed"
        fi
    fi
}

# ─── Pokemon Colorscripts ────────────────────────────────────────────────────
setup_pokemon() {
    header "Pokemon Colorscripts"
    if command_exists pokemon-colorscripts; then
        ok "pokemon-colorscripts already installed"
        return
    fi
    local tmpdir; tmpdir=$(mktemp -d)
    git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$tmpdir/pokemon-colorscripts"
    if [[ "$OS" == "macos" ]]; then
        (cd "$tmpdir/pokemon-colorscripts" && sudo ./install.sh)
    else
        (cd "$tmpdir/pokemon-colorscripts" && sudo ./install.sh)
    fi
    rm -rf "$tmpdir"
    ok "pokemon-colorscripts installed"
}

# ─── JetBrainsMono Nerd Font ─────────────────────────────────────────────────
setup_fonts() {
    header "JetBrainsMono Nerd Font"
    if [[ "$OS" == "macos" ]]; then
        if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null 2>&1; then
            ok "JetBrainsMono Nerd Font already installed"
        else
            info "Installing JetBrainsMono Nerd Font via brew..."
            brew tap homebrew/cask-fonts 2>/dev/null || true
            brew_cask_install font-jetbrains-mono-nerd-font
        fi
    else
        local font_dir="$HOME/.local/share/fonts"
        if fc-list | grep -qi "JetBrainsMono"; then
            ok "JetBrainsMono Nerd Font already installed"
        else
            info "Installing JetBrainsMono Nerd Font..."
            local tmpdir; tmpdir=$(mktemp -d)
            local version
            version=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
                | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
            curl -fsSL \
                "https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/JetBrainsMono.tar.xz" \
                -o "$tmpdir/JetBrainsMono.tar.xz"
            mkdir -p "$font_dir"
            tar -xf "$tmpdir/JetBrainsMono.tar.xz" -C "$font_dir"
            fc-cache -fv "$font_dir" &>/dev/null
            rm -rf "$tmpdir"
            ok "JetBrainsMono Nerd Font installed"
        fi
    fi
}

# ─── Git (install + config) ───────────────────────────────────────────────────
setup_git() {
    header "Git"
    if [[ "$OS" == "macos" ]]; then
        brew_install git
    else
        apt_install git
    fi
    symlink "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
}

# ─── Docker ──────────────────────────────────────────────────────────────────
setup_docker() {
    header "Docker"
    if [[ "$OS" == "macos" ]]; then
        brew_cask_install docker
        ok "Docker Desktop installed — open it from /Applications to complete setup"
    else
        if command_exists docker; then
            ok "Docker already installed"
        else
            info "Installing Docker Engine via official script..."
            curl -fsSL https://get.docker.com | sudo sh
        fi

        # Add current user to docker group so sudo isn't needed
        if ! groups "$USER" | grep -q docker; then
            info "Adding $USER to docker group..."
            sudo usermod -aG docker "$USER"
            warn "Log out and back in for docker group membership to take effect"
        else
            ok "$USER is already in the docker group"
        fi

        # Enable + start Docker service
        sudo systemctl enable docker
        sudo systemctl start docker
        ok "Docker service enabled and started"
    fi

    # Docker Compose (v2 plugin — included with Docker Desktop on macOS,
    # needs explicit install on Linux for older setups)
    if [[ "$OS" == "linux" ]]; then
        if ! docker compose version &>/dev/null 2>&1; then
            info "Installing Docker Compose v2 plugin..."
            local compose_ver
            compose_ver=$(curl -s https://api.github.com/repos/docker/compose/releases/latest \
                | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
            local arch; arch=$(uname -m)
            sudo mkdir -p /usr/local/lib/docker/cli-plugins
            sudo curl -fsSL \
                "https://github.com/docker/compose/releases/download/v${compose_ver}/docker-compose-linux-${arch}" \
                -o /usr/local/lib/docker/cli-plugins/docker-compose
            sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
            ok "Docker Compose v2 installed"
        else
            ok "Docker Compose v2 already available"
        fi
    fi
}

# ─── Sublime Text ────────────────────────────────────────────────────────────
setup_sublime_text() {
    header "Sublime Text"
    if [[ "$OS" == "macos" ]]; then
        brew_cask_install sublime-text
    else
        if ! command_exists subl; then
            info "Adding Sublime Text apt repo..."
            wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
                | gpg --dearmor | sudo tee /usr/share/keyrings/sublimehq-archive.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/sublimehq-archive.gpg] https://download.sublimetext.com/ apt/stable/" \
                | sudo tee /etc/apt/sources.list.d/sublime-text.list
            sudo apt-get update -qq
            apt_install sublime-text
        else
            ok "Sublime Text already installed"
        fi
    fi
}

# ─── Sublime Merge ────────────────────────────────────────────────────────────
setup_sublime_merge() {
    header "Sublime Merge"
    if [[ "$OS" == "macos" ]]; then
        brew_cask_install sublime-merge
    else
        if ! command_exists smerge; then
            info "Adding Sublime Merge apt repo..."
            wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
                | gpg --dearmor | sudo tee /usr/share/keyrings/sublimehq-archive.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/sublimehq-archive.gpg] https://download.sublimetext.com/ apt/stable/" \
                | sudo tee /etc/apt/sources.list.d/sublime-text.list
            sudo apt-get update -qq
            apt_install sublime-merge
        else
            ok "Sublime Merge already installed"
        fi
    fi
}

# ─── VS Code ─────────────────────────────────────────────────────────────────
setup_vscode() {
    header "VS Code"
    if [[ "$OS" == "macos" ]]; then
        brew_cask_install visual-studio-code
    else
        if ! command_exists code; then
            info "Adding VS Code apt repo..."
            wget -qO - https://packages.microsoft.com/keys/microsoft.asc \
                | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
                | sudo tee /etc/apt/sources.list.d/vscode.list
            sudo apt-get update -qq
            apt_install code
        else
            ok "VS Code already installed"
        fi
    fi
}

# ─── Firefox ─────────────────────────────────────────────────────────────────
setup_firefox() {
    header "Firefox"
    if [[ "$OS" == "macos" ]]; then
        brew_cask_install firefox
    else
        if ! command_exists firefox; then
            # Install from Mozilla PPA (not snap)
            info "Adding Mozilla PPA for Firefox..."
            sudo add-apt-repository -y ppa:mozillateam/ppa
            echo 'Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001' | sudo tee /etc/apt/preferences.d/mozilla-firefox
            sudo apt-get update -qq
            apt_install firefox
        else
            ok "Firefox already installed"
        fi
    fi
}

# ─── Bitwarden ───────────────────────────────────────────────────────────────
setup_bitwarden() {
    header "Bitwarden"
    if [[ "$OS" == "macos" ]]; then
        brew_cask_install bitwarden
    else
        if ! command_exists bitwarden; then
            info "Downloading Bitwarden AppImage for Linux..."
            local version
            version=$(curl -s https://api.github.com/repos/bitwarden/clients/releases \
                | grep '"tag_name"' | grep 'desktop' | head -1 \
                | sed 's/.*"desktop-v\([^"]*\)".*/\1/')
            local appimage_url="https://github.com/bitwarden/clients/releases/download/desktop-v${version}/Bitwarden-${version}-x86_64.AppImage"
            mkdir -p "$HOME/.local/bin"
            curl -fsSL "$appimage_url" -o "$HOME/.local/bin/bitwarden.AppImage"
            chmod +x "$HOME/.local/bin/bitwarden.AppImage"
            ok "Bitwarden AppImage installed at ~/.local/bin/bitwarden.AppImage"
        else
            ok "Bitwarden already installed"
        fi
    fi
    echo ""
    info "Bitwarden browser extensions (install manually):"
    echo "  Firefox : https://addons.mozilla.org/firefox/addon/bitwarden-password-manager/"
    echo "  Chrome  : https://chrome.google.com/webstore/detail/bitwarden/nngceckbapebfimnlniiiahkandclblb"
    if [[ "$OS" == "macos" ]]; then
        echo "  Safari  : https://apps.apple.com/app/bitwarden/id1352778147"
    fi
}

# ─── Spotify ─────────────────────────────────────────────────────────────────
setup_spotify() {
    header "Spotify"
    if [[ "$OS" == "macos" ]]; then
        brew_cask_install spotify
    else
        if ! command_exists spotify; then
            curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg \
                | gpg --dearmor | sudo tee /usr/share/keyrings/spotify.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/spotify.gpg] http://repository.spotify.com stable non-free" \
                | sudo tee /etc/apt/sources.list.d/spotify.list
            sudo apt-get update -qq
            apt_install spotify-client
        else
            ok "Spotify already installed"
        fi
    fi
}

# ─── Discord ─────────────────────────────────────────────────────────────────
setup_discord() {
    header "Discord"
    if [[ "$OS" == "macos" ]]; then
        brew_cask_install discord
    else
        if ! command_exists discord; then
            local tmpdir; tmpdir=$(mktemp -d)
            info "Downloading Discord .deb..."
            curl -fsSL "https://discord.com/api/download?platform=linux&format=deb" \
                -o "$tmpdir/discord.deb"
            sudo apt-get install -y "$tmpdir/discord.deb"
            rm -rf "$tmpdir"
        else
            ok "Discord already installed"
        fi
    fi
}

# ─── OpenCode ────────────────────────────────────────────────────────────────
setup_opencode() {
    header "OpenCode"
    if command_exists opencode; then
        ok "OpenCode already installed"
        return
    fi
    info "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
    ok "OpenCode installed"
}

# ─── GitHub Copilot (VS Code extension + CLI) ────────────────────────────────
setup_github_copilot() {
    header "GitHub Copilot"

    # VS Code extensions
    if command_exists code; then
        info "Installing GitHub Copilot VS Code extensions..."
        code --install-extension GitHub.copilot
        code --install-extension GitHub.copilot-chat
        ok "GitHub Copilot VS Code extensions installed"
    else
        warn "VS Code not installed — skipping Copilot VS Code extensions"
    fi

    # CLI extension (gh extension install github/gh-copilot)
    if command_exists gh; then
        if gh extension list 2>/dev/null | grep -q "gh-copilot"; then
            ok "GitHub Copilot CLI extension already installed"
        else
            info "Installing GitHub Copilot CLI extension..."
            gh extension install github/gh-copilot
            ok "GitHub Copilot CLI extension installed (use: gh copilot suggest / gh copilot explain)"
        fi
    else
        info "Installing gh (GitHub CLI) first..."
        if [[ "$OS" == "macos" ]]; then
            brew_install gh
        else
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
                | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
                | sudo tee /etc/apt/sources.list.d/github-cli.list
            sudo apt-get update -qq
            apt_install gh
        fi
        info "Installing GitHub Copilot CLI extension..."
        gh extension install github/gh-copilot
        ok "GitHub Copilot CLI extension installed (use: gh copilot suggest / gh copilot explain)"
    fi
}

# ─── NordVPN ─────────────────────────────────────────────────────────────────
setup_nordvpn() {
    header "NordVPN"
    if [[ "$OS" == "macos" ]]; then
        brew_cask_install nordvpn
    else
        if command_exists nordvpn; then
            ok "NordVPN already installed"
        else
            info "Installing NordVPN for Linux..."
            curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh | sudo sh
            # Add current user to nordvpn group so sudo isn't needed
            if ! groups "$USER" | grep -q nordvpn; then
                sudo usermod -aG nordvpn "$USER"
                warn "Log out and back in for nordvpn group membership to take effect"
            fi
            ok "NordVPN installed — run: nordvpn login"
        fi
    fi
}

# ─── Claude ──────────────────────────────────────────────────────────────────
setup_claude() {
    header "Claude"
    if [[ "$OS" == "macos" ]]; then
        info "Installing Claude Desktop (macOS)..."
        brew_cask_install claude
    else
        info "Installing Claude Code (Linux)..."
        if command_exists claude; then
            ok "Claude Code already installed"
        else
            # Claude Code is distributed as an npm package
            if command_exists npm; then
                npm install -g @anthropic-ai/claude-code
                ok "Claude Code installed"
            else
                warn "npm not found — install Node.js first, then run: npm install -g @anthropic-ai/claude-code"
            fi
        fi
    fi
}

# ─── Main menu ───────────────────────────────────────────────────────────────
main() {
    detect_os

    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║       garethrhughes/local setup          ║${RESET}"
    echo -e "${BOLD}${CYAN}║  OS: $(printf '%-36s' "${OS}$([ "$OS" = linux ] && echo " ($DISTRO)")")║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${RESET}"
    echo ""

    # ── OS bootstrap (always runs) ──
    if [[ "$OS" == "macos" ]]; then
        setup_macos_bootstrap
    else
        setup_linux_bootstrap
    fi

    # ── Interactive menu ──
    declare -A SELECTED

    items=(
        "disable_snap:Disable Snap (Kubuntu only)"
        "fonts:JetBrainsMono Nerd Font"
        "fish:Fish Shell + config"
        "terminal:Terminal (Ghostty/macOS · Kitty/Linux)"
        "starship:Starship Prompt"
        "neovim:Neovim (nvim-setup)"
        "asdf:asdf version manager"
        "nodejs:Node.js (via asdf)"
        "cli_tools:Core CLI tools (bat, fzf, ripgrep, fd)"
        "granted:Granted (AWS assume)"
        "pokemon:Pokemon Colorscripts"
        "git:Git + config"
        "docker:Docker"
        "sublime_text:Sublime Text"
        "sublime_merge:Sublime Merge"
        "vscode:VS Code"
        "firefox:Firefox"
        "bitwarden:Bitwarden (+ browser extension links)"
        "spotify:Spotify"
        "discord:Discord"
        "opencode:OpenCode"
        "github_copilot:GitHub Copilot (VS Code extensions + CLI)"
        "claude:Claude (Desktop/macOS · Claude Code/Linux)"
        "nordvpn:NordVPN"
    )

    echo -e "${BOLD}Select components to install:${RESET}"
    echo -e "${YELLOW}(press Enter to accept default [Y/n])${RESET}\n"

    for item in "${items[@]}"; do
        key="${item%%:*}"
        label="${item#*:}"

        # Skip OS-specific items
        if [[ "$key" == "disable_snap" && "$OS" != "linux" ]]; then continue; fi

        if prompt_yn "  Install $label?" y; then
            SELECTED[$key]=1
        else
            SELECTED[$key]=0
        fi
    done

    echo ""
    header "Starting Installation"

    [[ "${SELECTED[disable_snap]:-0}" == "1" ]] && disable_snap
    [[ "${SELECTED[fonts]:-0}" == "1" ]]        && setup_fonts
    [[ "${SELECTED[fish]:-0}" == "1" ]]         && setup_fish
    [[ "${SELECTED[terminal]:-0}" == "1" ]]     && setup_terminal
    [[ "${SELECTED[starship]:-0}" == "1" ]]     && setup_starship
    [[ "${SELECTED[asdf]:-0}" == "1" ]]         && setup_asdf
    [[ "${SELECTED[nodejs]:-0}" == "1" ]]       && setup_nodejs
    [[ "${SELECTED[neovim]:-0}" == "1" ]]       && setup_neovim
    [[ "${SELECTED[cli_tools]:-0}" == "1" ]]    && setup_cli_tools
    [[ "${SELECTED[granted]:-0}" == "1" ]]      && setup_granted
    [[ "${SELECTED[pokemon]:-0}" == "1" ]]      && setup_pokemon
    [[ "${SELECTED[git]:-0}" == "1" ]]          && setup_git
    [[ "${SELECTED[docker]:-0}" == "1" ]]       && setup_docker
    [[ "${SELECTED[sublime_text]:-0}" == "1" ]] && setup_sublime_text
    [[ "${SELECTED[sublime_merge]:-0}" == "1" ]]&& setup_sublime_merge
    [[ "${SELECTED[vscode]:-0}" == "1" ]]       && setup_vscode
    [[ "${SELECTED[firefox]:-0}" == "1" ]]      && setup_firefox
    [[ "${SELECTED[bitwarden]:-0}" == "1" ]]    && setup_bitwarden
    [[ "${SELECTED[spotify]:-0}" == "1" ]]      && setup_spotify
    [[ "${SELECTED[discord]:-0}" == "1" ]]      && setup_discord
    [[ "${SELECTED[opencode]:-0}" == "1" ]]     && setup_opencode
    [[ "${SELECTED[github_copilot]:-0}" == "1" ]] && setup_github_copilot
    [[ "${SELECTED[claude]:-0}" == "1" ]]       && setup_claude
    [[ "${SELECTED[nordvpn]:-0}" == "1" ]]      && setup_nordvpn

    echo ""
    ok "Setup complete! Restart your terminal for all changes to take effect."
    if [[ "${SELECTED[fish]:-0}" == "1" ]]; then
        info "If fish was set as your default shell, log out and back in for the change to take effect."
    fi
}

main "$@"
