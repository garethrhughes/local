if status is-interactive
    # Commands to run in interactive sessions can go here

   alias assume="source /opt/homebrew/bin/assume.fish"
   alias kssh "kitty +kitten ssh"
   source ~/.asdf/asdf.fish
   source ~/.config/fish/completions/granted_completer_fish.fish
   
   starship init fish | source
end

function fish_greeting
     pokemon-colorscripts -r 1-2 --no-title 
end

