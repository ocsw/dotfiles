#!/usr/bin/env bash

# see common.sh
npm () {
    local arg
    local is_install="no"
    local is_global="no"
    for arg in "$@"; do
        if [ "$arg" = "install" ]; then
            is_install="yes"
        fi
        if [ "$arg" = "-g" ] || [ "$arg" = "--global" ]; then
            is_global="yes"
        fi
    done
    if [ "$is_install" = "yes" ] && [ "$is_global" = "yes" ]; then
        umask_wrap 022 npm "$@"
        return "$?"
    fi
    command npm "$@"
}

if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [ -s "/usr/local/opt/nvm/nvm.sh" ] && \
        . "/usr/local/opt/nvm/nvm.sh"
    # shellcheck disable=SC1091
    [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \
        . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
fi
