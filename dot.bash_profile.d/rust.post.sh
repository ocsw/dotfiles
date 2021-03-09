#!/usr/bin/env bash

if [ -f "${HOME}/.cargo/bin/rustc" ] ||
        is_available rustc && [ -d "${HOME}/.cargo/bin" ]; then
    if ! is_path_component "${HOME}/.cargo/bin"; then
        export PATH="${PATH}:${HOME}/.cargo/bin"
    fi
fi
