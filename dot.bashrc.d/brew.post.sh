#!/usr/bin/env bash

# See also ../dot.bash_profile.d/brew.first.sh

# See common.sh
brew () {
    umask_wrap 022 brew "$@"
}

# Can't use is_available() because we defined a function with the same name
if in_path brew; then
    brew-fix-perms () {
        if [ -d /usr/local/Cellar ]; then
            # Be conservative; we don't want to include something that really
            # shouldn't be world-accessible
            # The path implies macOS, on which find has -exec + (and chmod has
            # -h)
            find /usr/local/{Cellar,Caskroom} \
                \( -name '__pycache__' -o -name '*.pyc' \) \! -perm -044 \
                -exec chmod -h go=u-w {} +
        fi
        if [ -d /opt/homebrew ]; then
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
