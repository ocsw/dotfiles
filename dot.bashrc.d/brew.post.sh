#!/usr/bin/env bash

# see common.sh
brew () {
    umask_wrap 022 brew "$@"
}

# can't use is_available() because we just defined a function with the same name
if in_path brew; then
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
