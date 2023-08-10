#!/usr/bin/env bash

# for Mac brew package
# can't use is_available() for brew because we defined a function with the same
# name
if in_path brew && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    # shellcheck disable=SC1091
    . "$(brew --prefix)/etc/bash_completion"
fi
