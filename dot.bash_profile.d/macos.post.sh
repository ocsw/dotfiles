#!/usr/bin/env bash

if [ "$(uname)" = "Darwin" ]; then
    # See also brew.first.sh
    if ! is_path_component "/usr/local/sbin" && [ -d /usr/local/sbin ]; then
        export PATH="${PATH//:\/usr\/sbin:/:/usr/local/sbin:/usr/sbin:}"
    fi

    # silence warning when using /bin/bash on 10.15+ (Catalina)
    export BASH_SILENCE_DEPRECATION_WARNING=1
fi
