#!/bin/bash

col=$1
proc=$$
if [ "$2" = "tmux" ] || [ "$3" = "tmux" ]
then
    printf "\033Ptmux;\033\033]$col;?\007\033\\" >> /dev/tty
else
    if [ "$2" = "7" ] || [ "$3" == "7" ]
    then
        printf "\033]$col;?\007" >> /dev/tty
    else
        printf "\033]$col;?\033\\" >> /dev/tty
    fi
fi
(sleep 0.05; kill $proc >> /dev/null;)&
child1=$!
read -r -t 1 -d $'\x1b'
if [ "$2" = "7" ] || [ "$3" == "7" ]
then
    read -r -t 1 -d $'\007' color
else
    read -r -t 1 -d $'\\' color
fi
kill $child1 2>/dev/null
wait $child1 2>/dev/null
echo $color
