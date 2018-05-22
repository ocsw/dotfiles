#!/usr/bin/env bash

# for Mac brew package
if in_path brew && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    # shellcheck disable=SC1090
    . "$(brew --prefix)/etc/bash_completion"
fi
