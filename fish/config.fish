if status is-interactive
    # Commands to run in interactive sessions can go here

   alias assume="source /usr/local/bin/assume.fish"
   alias bat "batcat"
   alias kssh "kitty +kitten ssh"
   source ~/.asdf/asdf.fish

   starship init fish | source
end

function fish_greeting
     pokemon-colorscripts -r 1-2 --no-title 
end

