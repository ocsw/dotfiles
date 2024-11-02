#!/usr/bin/env bash

if is_available rustc || [ -f "${HOME}/.cargo/bin/rustc" ]; then
    if ! is_path_component "${HOME}/.cargo/bin" && \
            [ -d "${HOME}/.cargo/bin" ]; then
        export PATH="${PATH}:${HOME}/.cargo/bin"
    fi
fi
