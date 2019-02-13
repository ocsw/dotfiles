#!/usr/bin/env bash

brew-fix-perms () {
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
    chmod -R go=u-w /usr/local
    find /usr/local \! -perm 444 -a \! -perm 555 -a \! -perm 644 -a \
        \! -perm 755 -a \! -perm 775 -print0 | \
        xargs -0 chmod -h go=u-w
}
