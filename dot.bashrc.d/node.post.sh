#!/usr/bin/env bash

# See also ../dot.bash_profile.d/node.post.sh

# See common.sh
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

# See ../dot.bash_profile.d/node.post.sh
if [ -n "$NVM_DIR" ]; then
    # Can't use is_available() for brew because we defined a function with the
    # same name
    if in_path brew; then
        # shellcheck disable=SC1091
        [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] &&
            . "$(brew --prefix)/opt/nvm/nvm.sh"
        # shellcheck disable=SC1091
        [ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] &&
            . "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"
    fi
fi
