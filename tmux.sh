#!/bin/bash
success=false
exec < /dev/tty
oldstty=$(stty -g)
stty raw -echo min 0
col=$1      # background
#          OSC   Ps  ;Pt ST
printf "\033Ptmux;\e\033]$col;?\007\033\\" > /dev/tty
result=
if IFS=';' read -t 1 -r -d '\' color ; then
    result=$(echo $color | sed 's/^.*\;//;s/[^rgb:0-9a-f/]//g')
    success=true
fi
stty $oldstty
echo $result
$success
