#!/usr/bin/env bash

# See also ../dot.bash_profile.d/brew.first.sh

# See common.sh
brew () {
    umask_wrap 022 brew "$@"
}

# Can't use is_available() because we defined a function with the same name
if in_path brew; then
    brew-fix-perms () {
        if [ -e /usr/local/Cellar ]; then
            # Only include directories we know are Brew-related (we would have
            # installed gcloud, node, python, and ruby via Brew, and they could
            # have accumulated files with "incorrect" permissions as components
            # / modules / packages / gems got installed or run)
            for i in Caskroom Cellar Homebrew lib/node_modules lib/python* \
                    lib/ruby share/google-cloud-sdk var/homebrew; do
                [ -e "/usr/local/${i}" ] && chmod -R go=u-w "/usr/local/${i}"
            done
        fi
        if [ -e /opt/homebrew ]; then
            chmod -R go=u-w /opt/homebrew
        fi
    }

    brew-up () {
        brew update
        brew upgrade
        brew-fix-perms
        brew cleanup
        brew doctor
    }

    brew-keg-only () {
        brew info --installed --json=v1 |
            jq "map(select(.keg_only == true)) | map(.name)" | grep '"' |
            sed -e 's/^ *"//' -e 's/",$//' -e 's/"$//'
    }

    # For the brew bash-completion package
    if [ -e "$(brew --prefix)/etc/bash_completion" ]; then
        # shellcheck disable=SC1091
        . "$(brew --prefix)/etc/bash_completion"
    fi
fi
