#!/usr/bin/env bash

if is_available hstr; then
    HSTR_CONFIG="hicolor"
    HSTR_CONFIG="${HSTR_CONFIG},prompt-bottom"
    HSTR_CONFIG="${HSTR_CONFIG},raw-history-view"
    #HSTR_CONFIG="${HSTR_CONFIG},duplicates"
    HSTR_CONFIG="${HSTR_CONFIG},verbose-kill"
    #HSTR_CONFIG="${HSTR_CONFIG},blacklist"
    HSTR_CONFIG="${HSTR_CONFIG},warning"

    alias hh="hstr"
    alias hhn="hstr -n"
fi

# TODO
# ~/.hstr_favorites
# ~/.hstr_blacklist
# HSTR_PROMPT
# export HISTCONTROL=ignorespace
# if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hstr -- \C-j"'; fi
