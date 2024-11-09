#!/usr/bin/env bash

if is_available flux; then
    # Can't use is_available() because we defined a function with the same name
    if ! in_path brew ||
            ! [ -f "${HOMEBREW_PREFIX}/etc/bash_completion.d/flux" ]; then
        # See https://fluxcd.io/flux/installation/
        # shellcheck disable=SC1090
        . <(flux completion bash)  # why is this not working???
    fi
fi
