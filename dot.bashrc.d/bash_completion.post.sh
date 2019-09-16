#!/usr/bin/env bash

# for Mac brew package
if is_available brew && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    # shellcheck disable=SC1090
    . "$(brew --prefix)/etc/bash_completion"
fi
