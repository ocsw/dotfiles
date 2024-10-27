#!/usr/bin/env bash

if kubectl krew version > /dev/null 2>&1; then
    if ! is_path_component "${HOME}/.krew/bin" &&
            [ -d "${HOME}/.krew/bin" ]; then
        export PATH="${PATH}:${HOME}/.krew/bin"
    fi
fi
