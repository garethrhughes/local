#!/bin/sh

printf '
  \033[1mkitty cheatsheet\033[0m

  \033[36msplits\033[0m
    \033[1mcmd+d\033[0m                 \033[2mvertical split\033[0m
    \033[1mcmd+shift+d\033[0m           \033[2mhorizontal split\033[0m
    \033[1mcmd+[ / cmd+]\033[0m         \033[2mmove between splits\033[0m
    \033[1mcmd+shift+[ / ]\033[0m       \033[2mmove up / down\033[0m
    \033[1mcmd+shift+f\033[0m           \033[2mzoom toggle (stack layout)\033[0m
    \033[1mcmd+w\033[0m                 \033[2mclose split / tab\033[0m

  \033[36mtabs\033[0m
    \033[1mcmd+t\033[0m                 \033[2mnew tab in cwd\033[0m
    \033[1mcmd+1..9\033[0m              \033[2mjump to tab N\033[0m

  \033[36mhints\033[0m \033[2m(letter overlays for keyboard pickup)\033[0m
    \033[1mctrl+shift+e\033[0m          \033[2mopen URL\033[0m
    \033[1mctrl+shift+p f\033[0m        \033[2mcopy file path\033[0m
    \033[1mctrl+shift+p shift+f\033[0m  \033[2mopen file in $EDITOR\033[0m
    \033[1mctrl+shift+p l\033[0m        \033[2mline numbers from grep\033[0m
    \033[1mctrl+shift+p h\033[0m        \033[2mgit commit hashes\033[0m
    \033[1mctrl+shift+p w\033[0m        \033[2mwords\033[0m

  \033[36mscrollback\033[0m
    \033[1mcmd+shift+o\033[0m           \033[2mscrollback in less\033[0m
    \033[1mcmd+shift+g\033[0m           \033[2mlast command output → less\033[0m

  \033[36mmisc\033[0m
    \033[1mcmd+r\033[0m                 \033[2mreload config\033[0m
    \033[1mcmd+shift+a m / l\033[0m     \033[2mincrease / decrease opacity\033[0m
    \033[1mcmd+shift+slash\033[0m       \033[2mthis cheatsheet\033[0m

  \033[33mbuilt-in kittens\033[0m \033[2m(run from any kitty terminal)\033[0m
    \033[1mkitty +kitten ssh host\033[0m         \033[2mssh with terminfo + config\033[0m
    \033[1mkitty +kitten diff a b\033[0m         \033[2mside-by-side syntax diff\033[0m
    \033[1mkitty +kitten themes\033[0m           \033[2minteractive theme browser\033[0m
    \033[1mkitty +kitten icat img.png\033[0m     \033[2mrender image inline\033[0m
    \033[1mkitty +kitten clipboard\033[0m        \033[2mread/write system clipboard\033[0m
    \033[1mkitty +kitten hyperlinked-grep\033[0m \033[2mrg with clickable results\033[0m
    \033[1mkitty +kitten unicode-input\033[0m    \033[2mpick unicode by name\033[0m
    \033[1mkitty +kitten ask\033[0m              \033[2mprompt for input in scripts\033[0m

  \033[33msessions\033[0m \033[2m(launch with: kitty --session ~/.config/kitty/work.session)\033[0m
    \033[1mnew_tab name\033[0m                   \033[2mopen a new tab\033[0m
    \033[1mcd ~/path\033[0m                      \033[2mset working dir for next launch\033[0m
    \033[1mlaunch zsh\033[0m                     \033[2mrun a command in a window\033[0m
    \033[1mlaunch --location=vsplit zsh\033[0m   \033[2mopen as vertical split\033[0m
    \033[1mfocus\033[0m                          \033[2mfocus this tab on startup\033[0m

  \033[2mpress cmd+w to close\033[0m

'
