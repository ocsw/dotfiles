#!/usr/bin/env bash

if is_available gem; then
    gem () {
        local reset_umask
        local real_gem
        reset_umask=$(umask -p)
        # shellcheck disable=SC2230
        real_gem=$(which gem)
        umask 022
        "$real_gem" "$@"
        $reset_umask
    }
fi
