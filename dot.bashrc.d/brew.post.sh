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
            # It's possible etc or var has something that should actually be
            # user-only
            # (The -prune is needed because otherwise find will still descend
            # into the depth-1 directories recursively, even if nothing is done
            # with their contents.)
            (
                cd /opt/homebrew &&
                find . -depth 1 -prune \! -path ./etc \! -path ./var -print0 |
                    xargs -0 chmod -R go=u-w
                chmod -R go=u-w var/homebrew
            )
        fi
    }

    # See also all-up in updates.post.sh
    brew-up () {
        brew update
        brew upgrade
        brew-fix-perms
        brew cleanup
        brew doctor
    }

    # Requires jq
    brew-keg-only () {
        brew info --installed --json=v1 |
            jq "map(select(.keg_only == true)) | map(.name)" | grep '"' |
            sed -e 's/^ *"//' -e 's/",$//' -e 's/"$//'
    }

    # Requires jq
    brew-caveats () {
        # See
        # https://stackoverflow.com/questions/13333585/how-do-i-replay-the-caveats-section-from-a-homebrew-recipe/62022811#62022811
        brew info --installed --json=v1 |
            jq -r '.[] | select(.caveats != null) |
                "\nName: \(.name)\nCaveats: \(.caveats)"'
        brew info --installed --cask --json=v2 |
            jq -r '.casks[] | select(.caveats != null) |
                "\nName: \(.name)\nCaveats: \(.caveats)"'
    }

    # For the brew bash-completion package
    if [ -e "$(brew --prefix)/etc/bash_completion" ]; then
        # shellcheck disable=SC1091
        . "$(brew --prefix)/etc/bash_completion"
    fi
fi
