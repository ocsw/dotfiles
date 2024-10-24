#!/usr/bin/env bash

# Update All The Things


_fix-homedir-perms () {
    if [ "$(uname)" != "Darwin" ]; then
        chmod -R go-rwx "$HOME"
        return "$?"
    fi

    # Annoyingly, applications sometimes install things in various places in
    # ~/Library either as root, or with deeply screwy permissions.  The safest
    # thing to do is just ignore them.  The permissions on their
    # parent/ancestor directories should be enough protection.
    ### chmod -R go-rwx "$HOME" 2>&1 | \
    ###     grep -v \
    ###         -e "^chmod: Unable to change file mode on ${HOME}/Library/.*: Operation not permitted$" \
    ###         -e "^chmod: ${HOME}/Library/.*: Permission denied$"

    # However, as of Sonoma (macOS 14), that's not enough.  There's some kind
    # of issue with one of the protection systems that makes searching
    # ~/Library/Containers and ~/Library/Group Containers incredibly slow.
    # (See https://forums.developer.apple.com/forums/thread/740204 and
    # https://forums.macrumors.com/threads/daisydisk-very-slow-to-scan-in-sonoma.2406837/.)
    #
    # Here, find gets just the direct contents of $HOME and ~/Library, minus
    # ~/Library and ~/Library/*Containers.  The -prune is needed because
    # otherwise find will still descend into depth-1 directories recursively,
    # even if nothing is done with their contents.
    #
    # (See also sonoma.post.sh)
    (
        cd "$HOME" &&
        find . Library -depth 1 -prune \! -path ./Library \
            \! -regex "Library/.*Containers" -print0 |
        xargs -0 chmod -R go-rwx 2>&1 |
        grep -v \
            -e "^chmod: Unable to change file mode on Library/.*: Operation not permitted$" \
            -e "^chmod: Library/.*: Permission denied$"
    )
}

# wrapper for ease of overriding / adding to behavior
fix-homedir-perms () {
    _fix-homedir-perms
}


_all-up-header () {
    local color="1;36"  # bright cyan
    printf "%s\n" $'\e'"[${color}m*** $1 ***"$'\e[0m'
}

all-up () {
    # check global first
    local setup_repo="${SYSTEM_SETUP:-${HOME}/repos/system-setup}"

    echo

    if is_available brew-up; then
        _all-up-header "brew"
        brew-up
        echo
    fi

    if is_available gcloud-up; then
        _all-up-header "gcloud"
        echo "y" | gcloud-up
        echo
    fi

    if is_available kube-up; then
        _all-up-header "Kubernetes"
        kube-up
        echo
    fi

    if [ "${#GIT_REPOS_TO_UPDATE[@]}" != "0" ]; then
        _all-up-header "repos"
        git-update-repos
        echo

        _all-up-header "repo branches and stashes"
        git-update-repos -i
        echo
    fi

    _all-up-header ".bash_profile"
    # shellcheck disable=SC1091
    source "${HOME}/.bash_profile"
    echo

    if [ -d "$setup_repo" ]; then
        _all-up-header ".gitconfig"
        git-config-refresh
        git-config-check
        echo

        if [ -d "${HOME}/.vscode" ]; then
            _all-up-header "VSCode"
            vscode-check-config
            echo
        fi
    fi

    _all-up-header "perms"
    fix-homedir-perms
    echo
}
