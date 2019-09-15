#!/usr/bin/env bash

if in_path brew; then
    brew () {
        local reset_umask
        local real_brew
        reset_umask=$(umask -p)
        # shellcheck disable=SC2230
        real_brew=$(which brew)
        umask 022
        "$real_brew" "$@"
        $reset_umask
    }

    brew-up () {
        brew update
        brew upgrade
        brew cleanup
        brew doctor
    }

    brew-keg-only () {
        brew info --installed --json=v1 | \
            jq "map(select(.keg_only == true)) | map(.name)" | grep '"' | \
            sed -e 's/^ *"//' -e 's/",$//' -e 's/"$//'
    }
fi
