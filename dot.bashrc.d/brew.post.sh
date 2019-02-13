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

    brew-fix-perms () {
        # WARNING: CHANGE THIS IF YOU ADD ANYTHING SECRET TO /usr/local
        # (unlikely on a Mac)
        local gw="
            /usr/local/bin
            /usr/local/include
            /usr/local/sbin
            /usr/local/etc
            /usr/local/Homebrew
            /usr/local/var
            /usr/local/var/homebrew
            /usr/local/var/homebrew/linked
            /usr/local/lib
            /usr/local/opt
            /usr/local/Frameworks
            /usr/local/share
        "
        # shellcheck disable=SC2086
        chmod 775 $gw
        find /usr/local \! -perm -044 -print0 | xargs -0 chmod -h go=u-w
    }

    brew-up () {
        brew update
        brew upgrade
        brew cleanup
        brew doctor
    }
fi
