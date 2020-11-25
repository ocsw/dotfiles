#!/usr/bin/env bash

if [ "$(uname)" = "Darwin" ]; then
    # silence warning when using /bin/bash on 10.15+ (Catalina)
    export BASH_SILENCE_DEPRECATION_WARNING=1
fi
