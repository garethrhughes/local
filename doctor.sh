#!/usr/bin/env bash
# doctor.sh — Check installation health for garethrhughes/local setup
set -uo pipefail

# ─── Colours ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

PASS=0; WARN=0; FAIL=0
FIX_MODE=0
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Tracks component keys that have issues (space-separated, deduped via assoc array)
declare -A ISSUE_KEYS

pass()  { echo -e "  ${GREEN}✔${RESET}  $*"; ((PASS++)) || true; }
warn()  {
    echo -e "  ${YELLOW}⚠${RESET}  $*"
    ((WARN++)) || true
    if [[ -n "${_CURRENT_KEY:-}" ]]; then
        for _k in $_CURRENT_KEY; do ISSUE_KEYS["$_k"]=1; done
    fi
}
fail()  {
    echo -e "  ${RED}✘${RESET}  $*"
    ((FAIL++)) || true
    if [[ -n "${_CURRENT_KEY:-}" ]]; then
        for _k in $_CURRENT_KEY; do ISSUE_KEYS["$_k"]=1; done
    fi
}
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
    _CURRENT_KEY="fish"
    header "Shell"
    check_cmd fish "Fish shell"
    if [[ "$SHELL" == *fish* ]]; then
        pass "Fish is the default shell ($SHELL)"
    else
        warn "Fish is not the default shell (current: $SHELL)"
    fi
}

check_terminal() {
    _CURRENT_KEY="terminal"
    header "Terminal"
    check_cmd kitty "Kitty"
    check_file "$HOME/.config/kitty/kitty.conf" "Kitty config"
    check_file "$HOME/.config/kitty/tab_bar.py"  "Kitty tab_bar.py"
    if [[ "$OS" == "macos" ]]; then
        if command -v open &>/dev/null && open -Ra "Scroll Reverser" 2>/dev/null; then
            pass "Scroll Reverser installed"
        else
            warn "Scroll Reverser not found in /Applications"
        fi
    fi
}

check_prompt() {
    _CURRENT_KEY="starship"
    header "Prompt"
    check_cmd starship "Starship"
    check_file "$HOME/.config/starship.toml" "starship.toml"
}

check_fish_config() {
    _CURRENT_KEY="fish"
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
    _CURRENT_KEY="neovim"
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

check_nvm() {
    _CURRENT_KEY="nvm"
    header "Node.js (nvm)"
    # nvm.fish is the fish-native manager; check for it via fisher
    if command -v fish &>/dev/null; then
        if fish -c "fisher list" 2>/dev/null | grep -q "nvm.fish"; then
            pass "nvm.fish fisher plugin installed"
        else
            warn "nvm.fish fisher plugin not installed (run: fisher install jorgebucaran/nvm.fish)"
        fi
        local node_ver
        node_ver=$(fish -c "node --version" 2>/dev/null || true)
        if [[ -n "$node_ver" ]]; then
            pass "Node.js $node_ver (nvm.fish)"
        else
            warn "No active Node.js version in nvm.fish (run: nvm install lts)"
        fi
    fi
    # Also check standalone nvm on Linux
    if [[ "$OS" == "linux" ]]; then
        if [[ -d "$HOME/.nvm" ]]; then
            pass "nvm installed at ~/.nvm"
        else
            warn "~/.nvm not found"
        fi
    fi
    check_cmd node "node"
    check_cmd npm  "npm"
}

check_cli_tools() {
    _CURRENT_KEY="cli_tools"
    header "CLI Tools"
    check_cmd bat       "bat"
    check_cmd fzf       "fzf"
    check_cmd rg        "ripgrep"
    check_cmd fd        "fd"
    check_cmd pokemon-colorscripts "pokemon-colorscripts"
    check_file "$HOME/.config/bat/config" "bat config"
}

check_fonts() {
    _CURRENT_KEY="fonts"
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
    _CURRENT_KEY="git"
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
    _CURRENT_KEY="docker"
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
    _CURRENT_KEY="granted"
    header "Granted (AWS)"
    check_cmd granted "granted"
    check_cmd assume   "assume"
}

check_apps() {
    _CURRENT_KEY="sublime_text sublime_merge vscode firefox bitwarden spotify discord"
    header "Applications"
    if [[ "$OS" == "macos" ]]; then
        local -A app_keys=(
            ["Sublime Text"]="sublime_text"
            ["Sublime Merge"]="sublime_merge"
            ["Visual Studio Code"]="vscode"
            ["Firefox"]="firefox"
            ["Bitwarden"]="bitwarden"
            ["Spotify"]="spotify"
            ["Discord"]="discord"
        )
        local apps=("Sublime Text" "Sublime Merge" "Visual Studio Code" "Firefox" "Bitwarden" "Spotify" "Discord")
        for app in "${apps[@]}"; do
            _CURRENT_KEY="${app_keys[$app]}"
            if [[ -d "/Applications/${app}.app" ]] || \
               [[ -d "$HOME/Applications/${app}.app" ]]; then
                pass "$app"
            else
                fail "$app not found in /Applications"
            fi
        done
        _CURRENT_KEY="vscode"
        check_cmd code "VS Code CLI (code)"
    else
        _CURRENT_KEY="sublime_text"; check_cmd subl    "Sublime Text"
        _CURRENT_KEY="sublime_merge"; check_cmd smerge "Sublime Merge"
        _CURRENT_KEY="vscode"; check_cmd code          "VS Code"
        _CURRENT_KEY="firefox"; check_cmd firefox      "Firefox"
        _CURRENT_KEY="spotify"; check_cmd spotify      "Spotify"
        _CURRENT_KEY="discord"; check_cmd discord      "Discord"
    fi
    _CURRENT_KEY=""
}

check_opencode() {
    _CURRENT_KEY="opencode"
    header "OpenCode"
    check_cmd opencode "opencode"
}

check_nordvpn() {
    _CURRENT_KEY="nordvpn"
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
    _CURRENT_KEY="github_copilot"
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
    _CURRENT_KEY="disable_snap"
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
    _CURRENT_KEY=""
    header "Dotfile Symlinks"
    check_file "$HOME/.config/fish/config.fish"   "fish/config.fish"
    check_file "$HOME/.config/starship.toml"       "starship.toml"
    check_file "$HOME/.config/bat/config"          "bat/config"
    check_file "$HOME/.config/kitty/kitty.conf" "kitty/kitty.conf"
}

# ─── Summary + optional fix ──────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
    echo -e "${BOLD}  Doctor Summary${RESET}"
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
    echo -e "  ${GREEN}✔ Passed : $PASS${RESET}"
    echo -e "  ${YELLOW}⚠ Warnings: $WARN${RESET}"
    echo -e "  ${RED}✘ Failed : $FAIL${RESET}"
    echo ""
    if [[ "$FAIL" -gt 0 || "$WARN" -gt 0 ]]; then
        echo -e "${RED}${BOLD}Issues found. Run ./doctor.sh --fix to repair, or ./install.sh to reinstall components.${RESET}"
    else
        echo -e "${GREEN}${BOLD}Everything looks healthy!${RESET}"
    fi
}

run_fix() {
    if [[ "${#ISSUE_KEYS[@]}" -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}No fixable issues detected.${RESET}"
        return
    fi

    # Build label map from install.sh items array (duplicated here for portability)
    declare -A LABELS
    LABELS=(
        [disable_snap]="Disable Snap (Kubuntu only)"
        [fonts]="JetBrainsMono Nerd Font"
        [fish]="Fish Shell + config"
        [terminal]="Terminal (Kitty)"
        [starship]="Starship Prompt"
        [neovim]="Neovim (nvim-setup)"
        [nvm]="Node.js (via nvm)"
        [cli_tools]="Core CLI tools (bat, fzf, ripgrep, fd)"
        [granted]="Granted (AWS assume)"
        [pokemon]="Pokemon Colorscripts"
        [git]="Git + config"
        [docker]="Docker"
        [sublime_text]="Sublime Text"
        [sublime_merge]="Sublime Merge"
        [vscode]="VS Code"
        [firefox]="Firefox"
        [bitwarden]="Bitwarden"
        [spotify]="Spotify"
        [discord]="Discord"
        [opencode]="OpenCode"
        [github_copilot]="GitHub Copilot (VS Code extensions + CLI)"
        [claude]="Claude"
        [nordvpn]="NordVPN"
    )

    echo ""
    echo -e "${BOLD}${CYAN}── Fix Issues ──${RESET}"
    echo -e "${YELLOW}Select which components to fix (press Enter to accept default [Y/n]):${RESET}\n"

    local selected_keys=()
    for key in "${!ISSUE_KEYS[@]}"; do
        local label="${LABELS[$key]:-$key}"
        local ans
        read -r -p "$(echo -e "  ${BOLD}Fix ${label}? [Y/n]${RESET} ")" ans
        ans="${ans:-y}"
        if [[ "$ans" =~ ^[Yy] ]]; then
            selected_keys+=("$key")
        fi
    done

    if [[ "${#selected_keys[@]}" -eq 0 ]]; then
        echo -e "\n${YELLOW}No components selected — nothing to fix.${RESET}"
        return
    fi

    local only_arg
    only_arg=$(IFS=','; echo "${selected_keys[*]}")
    echo ""
    echo -e "${BOLD}Running: ./install.sh --only ${only_arg}${RESET}\n"
    bash "$DOTFILES_DIR/install.sh" --only "$only_arg"
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
    # Parse flags
    local fix=0
    for arg in "$@"; do
        [[ "$arg" == "--fix" ]] && fix=1
    done

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
    check_nvm
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

    if [[ "$fix" -eq 1 ]]; then
        run_fix
    fi

    if [[ "$FAIL" -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
