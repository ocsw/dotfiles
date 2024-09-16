#!/usr/bin/env bash

if is_available chef; then
    if ! [[ $PATH =~ /.chef/ ]]; then
        eval "$(chef shell-init "$(basename "$SHELL")" | grep 'export PATH=')"
    fi
fi
