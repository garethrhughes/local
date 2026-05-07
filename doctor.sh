#!/usr/bin/env bash
# doctor.sh — Check installation health for garethrhughes/local setup
set -uo pipefail

# ─── Colours ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

PASS=0; WARN=0; FAIL=0

pass()  { echo -e "  ${GREEN}✔${RESET}  $*"; ((PASS++)) || true; }
warn()  { echo -e "  ${YELLOW}⚠${RESET}  $*"; ((WARN++)) || true; }
fail()  { echo -e "  ${RED}✘${RESET}  $*"; ((FAIL++)) || true; }
header(){ echo -e "\n${BOLD}${CYAN}── $* ──${RESET}"; }

check_cmd() {
    local cmd="$1" label="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        local ver
        ver=$(command -v "$cmd" 2>/dev/null)
        pass "$label  ($(command -v "$cmd"))"
    else
        fail "$label  not found"
    fi
}

check_symlink() {
    local src="$1" dst="$2" label="${3:-}"
    [[ -z "$label" ]] && label="$dst"
    if [[ -L "$dst" ]]; then
        local target
        target=$(readlink "$dst")
        if [[ -e "$dst" ]]; then
            pass "Symlink: $label → $target"
        else
            fail "Symlink broken: $label → $target (target missing)"
        fi
    elif [[ -e "$dst" ]]; then
        warn "$label exists but is not a symlink (may be unmanaged)"
    else
        fail "$label missing"
    fi
}

check_file() {
    local path="$1" label="${2:-$1}"
    if [[ -f "$path" ]]; then
        pass "$label"
    else
        fail "$label not found"
    fi
}

check_dir() {
    local path="$1" label="${2:-$1}"
    if [[ -d "$path" ]]; then
        pass "$label"
    else
        fail "$label not found"
    fi
}

# ─── OS detect ───────────────────────────────────────────────────────────────
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then OS="macos"
    elif [[ -f /etc/os-release ]]; then . /etc/os-release; OS="linux"; DISTRO="${ID:-unknown}"
    else OS="unknown"
    fi
}

# ─── Checks ──────────────────────────────────────────────────────────────────
check_shell() {
    header "Shell"
    check_cmd fish "Fish shell"
    if [[ "$SHELL" == *fish* ]]; then
        pass "Fish is the default shell ($SHELL)"
    else
        warn "Fish is not the default shell (current: $SHELL)"
    fi
}

check_terminal() {
    header "Terminal"
    if [[ "$OS" == "macos" ]]; then
        check_cmd ghostty "Ghostty" || warn "Ghostty not on PATH (may need to open app manually)"
        check_file "$HOME/.config/ghostty/config" "Ghostty config"
        if command -v open &>/dev/null && open -Ra "Scroll Reverser" 2>/dev/null; then
            pass "Scroll Reverser installed"
        else
            warn "Scroll Reverser not found in /Applications"
        fi
    else
        check_cmd kitty "Kitty"
        check_file "$HOME/.config/kitty/kitty.conf" "Kitty config"
        check_file "$HOME/.config/kitty/tab_bar.py"  "Kitty tab_bar.py"
    fi
}

check_prompt() {
    header "Prompt"
    check_cmd starship "Starship"
    check_file "$HOME/.config/starship.toml" "starship.toml"
}

check_fish_config() {
    header "Fish Config"
    check_file "$HOME/.config/fish/config.fish"    "config.fish"
    check_file "$HOME/.config/fish/fish_plugins"   "fish_plugins"
    check_cmd fisher "fisher"

    # Plugins
    local plugins_expected=("jorgebucaran/fisher" "jethrokuan/fzf" "jorgebucaran/nvm.fish")
    for p in "${plugins_expected[@]}"; do
        if fish -c "fisher list" 2>/dev/null | grep -q "$p"; then
            pass "Fisher plugin: $p"
        else
            warn "Fisher plugin not installed: $p"
        fi
    done
}

check_nvim() {
    header "Neovim"
    check_cmd nvim "Neovim"
    if command -v nvim &>/dev/null; then
        local nvim_ver
        nvim_ver=$(nvim --version | head -1)
        pass "Version: $nvim_ver"
    fi
    check_dir "$HOME/.config/nvim" "~/.config/nvim"
    check_file "$HOME/dotfiles/nvim-setup/install.sh" "nvim-setup repo"
}

check_asdf() {
    header "asdf"
    check_cmd asdf "asdf"
    if command -v asdf &>/dev/null; then
        if asdf plugin list 2>/dev/null | grep -q nodejs; then
            pass "asdf nodejs plugin installed"
            local node_ver
            node_ver=$(asdf current nodejs 2>/dev/null | awk '{print $2}' || true)
            if [[ -n "$node_ver" && "$node_ver" != "______" ]]; then
                pass "Node.js $node_ver (asdf)"
            else
                warn "No global Node.js version set in asdf"
            fi
        else
            warn "asdf nodejs plugin not installed"
        fi
    fi
    check_cmd node "node"
    check_cmd npm  "npm"
}

check_cli_tools() {
    header "CLI Tools"
    check_cmd bat       "bat"
    check_cmd fzf       "fzf"
    check_cmd rg        "ripgrep"
    check_cmd fd        "fd"
    check_cmd pokemon-colorscripts "pokemon-colorscripts"
    check_file "$HOME/.config/bat/config" "bat config"
}

check_fonts() {
    header "Fonts"
    if [[ "$OS" == "macos" ]]; then
        if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null 2>&1; then
            pass "JetBrainsMono Nerd Font (brew cask)"
        else
            fail "JetBrainsMono Nerd Font not installed"
        fi
    else
        if fc-list 2>/dev/null | grep -qi "JetBrainsMono"; then
            pass "JetBrainsMono Nerd Font (fc-list)"
        else
            fail "JetBrainsMono Nerd Font not found (run fc-list to verify)"
        fi
    fi
}

check_git() {
    header "Git"
    check_cmd git "git"
    check_file "$HOME/.gitconfig" "~/.gitconfig"
    local git_name git_email
    git_name=$(git config --global user.name 2>/dev/null || true)
    git_email=$(git config --global user.email 2>/dev/null || true)
    if [[ -n "$git_name" ]]; then pass "git user.name: $git_name"; else warn "git user.name not set"; fi
    if [[ -n "$git_email" ]]; then pass "git user.email: $git_email"; else warn "git user.email not set"; fi
}

check_docker() {
    header "Docker"
    check_cmd docker "docker"
    if command -v docker &>/dev/null; then
        local docker_ver
        docker_ver=$(docker --version 2>/dev/null)
        pass "Version: $docker_ver"

        if docker info &>/dev/null 2>&1; then
            pass "Docker daemon is running"
        else
            warn "Docker daemon is not running (start Docker Desktop or 'sudo systemctl start docker')"
        fi

        if docker compose version &>/dev/null 2>&1; then
            pass "Docker Compose v2 available"
        else
            warn "Docker Compose v2 plugin not found"
        fi

        if [[ "$OS" == "linux" ]]; then
            if groups "$USER" | grep -q docker; then
                pass "$USER is in the docker group (no sudo needed)"
            else
                warn "$USER is not in the docker group (you may need sudo for docker commands)"
            fi
        fi
    fi
}

check_granted() {
    header "Granted (AWS)"
    check_cmd granted "granted"
    check_cmd assume   "assume"
}

check_apps() {
    header "Applications"
    if [[ "$OS" == "macos" ]]; then
        local apps=("Sublime Text" "Sublime Merge" "Visual Studio Code" "Firefox" "Bitwarden" "Spotify" "Discord")
        for app in "${apps[@]}"; do
            if [[ -d "/Applications/${app}.app" ]] || \
               [[ -d "$HOME/Applications/${app}.app" ]]; then
                pass "$app"
            else
                fail "$app not found in /Applications"
            fi
        done
        check_cmd code "VS Code CLI (code)"
    else
        check_cmd subl     "Sublime Text"
        check_cmd smerge   "Sublime Merge"
        check_cmd code     "VS Code"
        check_cmd firefox  "Firefox"
        check_cmd spotify  "Spotify"
        check_cmd discord  "Discord"
    fi
}

check_opencode() {
    header "OpenCode"
    check_cmd opencode "opencode"
}

check_nordvpn() {
    header "NordVPN"
    check_cmd nordvpn "nordvpn"
    if command -v nordvpn &>/dev/null; then
        local status
        status=$(nordvpn status 2>/dev/null | grep -i "Status" | head -1 || true)
        if [[ -n "$status" ]]; then
            pass "$status"
        fi
        if [[ "$OS" == "linux" ]]; then
            if groups "$USER" | grep -q nordvpn; then
                pass "$USER is in the nordvpn group (no sudo needed)"
            else
                warn "$USER is not in the nordvpn group (run: sudo usermod -aG nordvpn \$USER)"
            fi
        fi
    fi
}

check_vscode_extensions() {
    header "VS Code Extensions"
    if command -v code &>/dev/null; then
        local installed_exts
        installed_exts=$(code --list-extensions 2>/dev/null || true)
        local expected_exts=("GitHub.copilot" "GitHub.copilot-chat")
        for ext in "${expected_exts[@]}"; do
            if echo "$installed_exts" | grep -qi "$ext"; then
                pass "Extension: $ext"
            else
                warn "Extension not installed: $ext"
            fi
        done
    else
        warn "VS Code not installed — skipping extension checks"
    fi
}

check_snap_disabled() {
    if [[ "$OS" != "linux" ]]; then return; fi
    header "Snap (Linux)"
    if command -v snap &>/dev/null; then
        warn "snap is still installed/active"
    else
        pass "snap is disabled/not installed"
    fi
    if [[ -f /etc/apt/preferences.d/no-snap.pref ]]; then
        pass "no-snap.pref pinning file exists"
    else
        warn "no-snap.pref not found (snap may reinstall via apt)"
    fi
}

check_dotfiles_symlinks() {
    header "Dotfile Symlinks"
    check_file "$HOME/.config/fish/config.fish"   "fish/config.fish"
    check_file "$HOME/.config/starship.toml"       "starship.toml"
    check_file "$HOME/.config/bat/config"          "bat/config"
    if [[ "$OS" == "macos" ]]; then
        check_file "$HOME/.config/ghostty/config"  "ghostty/config"
    else
        check_file "$HOME/.config/kitty/kitty.conf" "kitty/kitty.conf"
    fi
}

# ─── Summary ─────────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
    echo -e "${BOLD}  Doctor Summary${RESET}"
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
    echo -e "  ${GREEN}✔ Passed : $PASS${RESET}"
    echo -e "  ${YELLOW}⚠ Warnings: $WARN${RESET}"
    echo -e "  ${RED}✘ Failed : $FAIL${RESET}"
    echo ""
    if [[ "$FAIL" -gt 0 ]]; then
        echo -e "${RED}${BOLD}Issues found. Run ./install.sh to fix missing components.${RESET}"
        exit 1
    elif [[ "$WARN" -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}All critical checks passed with warnings.${RESET}"
        exit 0
    else
        echo -e "${GREEN}${BOLD}Everything looks healthy!${RESET}"
        exit 0
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
    detect_os
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║       garethrhughes/local doctor         ║${RESET}"
    echo -e "${BOLD}${CYAN}║  OS: $(printf '%-36s' "${OS}$([ "$OS" = linux ] && echo " ($DISTRO)")")║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${RESET}"

    check_shell
    check_fonts
    check_terminal
    check_prompt
    check_fish_config
    check_nvim
    check_asdf
    check_cli_tools
    check_git
    check_docker
    check_granted
    check_apps
    check_opencode
    check_nordvpn
    check_vscode_extensions
    check_snap_disabled
    check_dotfiles_symlinks

    print_summary
}

main "$@"
