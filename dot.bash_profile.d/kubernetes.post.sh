#!/usr/bin/env bash

if [ -d "${HOME}/.krew/bin" ]; then
    if ! is_path_component "${HOME}/.krew/bin"; then
        export PATH="${PATH}:${HOME}/.krew/bin"
    fi
fi
