if status is-interactive
    set -g fish_color_autosuggestion '555'  'brblack'
    set -g fish_color_cancel -r
    set -g fish_color_command --bold
    set -g fish_color_comment red
    set -g fish_color_cwd green
    set -g fish_color_cwd_root red
    set -g fish_color_end brmagenta
    set -g fish_color_error brred
    set -g fish_color_escape 'bryellow'  '--bold'
    set -g fish_color_history_current --bold
    set -g fish_color_host normal
    set -g fish_color_match --background=brblue
    set -g fish_color_normal normal
    set -g fish_color_operator bryellow
    set -g fish_color_param cyan
    set -g fish_color_quote yellow
    set -g fish_color_redirection brblue
    set -g fish_color_search_match 'bryellow'  '--background=brblack'
    set -g fish_color_selection 'white'  '--bold'  '--background=brblack'
    set -g fish_color_user brgreen
    set -g fish_color_valid_path --underline

    # alias assume="source /usr/local/bin/assume.fish"
    alias kssh "kitty +kitten ssh"

    # asdf shims
    if test -z $ASDF_DATA_DIR
        set _asdf_shims "$HOME/.asdf/shims"
    else
        set _asdf_shims "$ASDF_DATA_DIR/shims"
    end
    if not contains $_asdf_shims $PATH
        set -gx --prepend PATH $_asdf_shims
    end
    set --erase _asdf_shims

    # asdf completions
    if test -f ~/.config/fish/completions/asdf.fish
        source ~/.config/fish/completions/asdf.fish
    end

    # granted completions
    if test -f ~/.config/fish/completions/granted_completer_fish.fish
        source ~/.config/fish/completions/granted_completer_fish.fish
    end

    # fzf shell integration
    if command -q fzf
        fzf --fish | source
    end

    starship init fish | source
end

function fish_greeting
    pokemon-colorscripts -r 1-2 --no-title
end
