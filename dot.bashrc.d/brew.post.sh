#!/usr/bin/env bash

# See also ../dot.bash_profile.d/brew.first.sh

# See common.sh
brew () {
    umask_wrap 022 brew "$@"
}

# Can't use is_available() because we defined a function with the same name
if in_path brew; then
    # For the brew bash-completion package
    if [ -e "$(brew --prefix)/etc/bash_completion" ]; then
        # shellcheck disable=SC1091
        . "$(brew --prefix)/etc/bash_completion"
    fi

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
        local linked_keg_only_formulas
        local unlinked_formulas

        brew update
        brew upgrade
        brew-fix-perms
        brew cleanup
        brew doctor

        # This doesn't seem to be caught by 'brew doctor', despite what the
        # docs say
        linked_keg_only_formulas=$(brew-keg-only-linked | sed 's/^/  /')
        if [ -n "$linked_keg_only_formulas" ]; then
            echo "There are linked keg-only formulas:"
            printf "%s\n" "$linked_keg_only_formulas"
        fi

        unlinked_formulas=$(brew-unlinked | sed 's/^/  /')
        if [ -n "$unlinked_formulas" ]; then
            echo "There are unlinked non-keg-only formulas:"
            printf "%s\n" "$unlinked_formulas"
        fi
    }

    # Requires jq
    brew-keg-only () {
        # See https://docs.brew.sh/Querying-Brew
        brew info --installed --json=v1 |
            jq -r '.[] | select(.keg_only == true) | .name'
    }

    # Requires jq
    brew-keg-only-linked () {
        # See https://docs.brew.sh/Querying-Brew#linked-keg-only-formulae
        brew info --installed --json=v1 |
            jq -r '.[] | select(.keg_only == true and .linked_keg != null) |
                .name'
    }

    # Requires jq
    brew-unlinked () {
        # See https://docs.brew.sh/Querying-Brew#unlinked-normal-formulae
        brew info --installed --json=v1 |
            jq -r '.[] | select(.keg_only == false and .linked_keg == null) |
                .name'
    }

    # Requires jq
    brew-caveats () {
        # See
        # https://stackoverflow.com/questions/13333585/how-do-i-replay-the-caveats-section-from-a-homebrew-recipe/62022811#62022811
        brew info --installed --json=v1 |
            jq -r '.[] | select(.caveats != null) |
                "\nName: \(.name)\nCaveats: \(.caveats)"'
        brew info --installed --json=v2 |
            jq -r '.casks[] | select(.caveats != null) |
                "\nName: \(.name)\nCaveats: \(.caveats)"'
    }
fi
