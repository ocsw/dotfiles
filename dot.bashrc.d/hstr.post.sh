#!/usr/bin/env bash

if is_available hstr; then
    HSTR_CONFIG="hicolor"
    HSTR_CONFIG="${HSTR_CONFIG},prompt-bottom"
    HSTR_CONFIG="${HSTR_CONFIG},raw-history-view"
    HSTR_CONFIG="${HSTR_CONFIG},duplicates"
    HSTR_CONFIG="${HSTR_CONFIG},verbose-kill"
    #HSTR_CONFIG="${HSTR_CONFIG},blacklist"
    HSTR_CONFIG="${HSTR_CONFIG},warning"
    export HSTR_CONFIG

    export HSTR_PROMPT="hstr> "

    [[ $- =~ .*i.* ]] && bind '"\C-r": "\C-ahstr -- \C-j"'

    alias hh="hstr"
    alias hhn="hstr -n"
fi

# ~/.hstr_favorites
# ~/.hstr_blacklist
# export HISTCONTROL=ignorespace
