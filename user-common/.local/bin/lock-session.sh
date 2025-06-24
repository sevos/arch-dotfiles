#!/bin/bash
# Lock session wrapper script that checks if swaylock is already running
# This prevents double-lock issues when suspend triggers while already locked

# Check if swaylock is already running
if ! pgrep -x swaylock > /dev/null; then
    # Run swaylock with the same parameters as in swayidle config
    swaylock --screenshots --effect-blur 7x5 --effect-vignette 0.5:0.5 \
             --ring-color 7fc8ff --key-hl-color ffffff --line-color 00000000 \
             --inside-color 00000088 --separator-color 00000000 \
             --grace 2 --fade-in 0.2
fi