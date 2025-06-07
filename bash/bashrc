#!/usr/bin/env bash

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi


mesg n

[[ -f /var/run/motd.dynamic ]] && cat /var/run/motd.dynamic

# make capslock also work for numbers
command -v setxkbmap >/dev/null 2>&1 && setxkbmap -option caps:shiftlock
