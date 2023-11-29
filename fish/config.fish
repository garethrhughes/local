if status is-interactive
    # Commands to run in interactive sessions can go here

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

   alias assume="source /usr/local/bin/assume.fish"
   alias kssh "kitty +kitten ssh"
   source ~/.asdf/asdf.fish
   source ~/.config/fish/completions/granted_completer_fish.fish
   
   starship init fish | source
end

function fish_greeting
     pokemon-colorscripts -r 1-2 --no-title 
end

