#!/usr/bin/env bash

# Update All The Things


_fix-homedir-perms () {
    if [ "$(uname)" != "Darwin" ]; then
        chmod -R go-rwx "$HOME"
        return "$?"
    fi

    #
    # Annoyingly, applications sometimes install things in various places in
    # ~/Library either as root, or with deeply screwy permissions.  The safest
    # thing to do is just ignore them.  The permissions on their
    # parent/ancestor directories should be enough protection.
    #
    # Similarly, the itch.io app installs itself into ~/Applications, and there
    # doesn't seem to be any way to change the permissions on its files.  And
    # at least as of macOS 26 Tahoe, ~/.Trash is also untouchable.
    #
    chmod -R go-rwx "$HOME" 2>&1 |
        grep -vE \
            -e "^chmod: Unable to change file mode on ${HOME}/(Applications|Library)/.*: Operation not permitted\$" \
            -e "^chmod: ${HOME}/\.Trash: Operation not permitted\$" \
            -e "^chmod: ${HOME}/Library/.*: Operation not permitted\$" \
            -e "^chmod: ${HOME}/Library/.*: Permission denied\$"
}

# Wrapper for ease of overriding / adding to behavior
# (See also all-up, below)
fix-homedir-perms () {
    _fix-homedir-perms
}


_all-up-header () {
    local color="1;36"  # bright cyan
    printf '\e[%sm*** %s ***\e[0m\n' "$color" "$1"
}

all-up () {
    echo

    # See brew.post.sh
    if is_available brew-up; then
        _all-up-header "brew"
        brew-up
        echo
    fi

    # See gcloud.post.sh
    if is_available gcloud-up; then
        _all-up-header "gcloud"
        echo "y" | gcloud-up
        echo
    fi

    # See kubernetes.post.sh
    if is_available krew-up; then
        _all-up-header "krew"
        krew-up
        echo
    fi

    # See git.post.sh
    if [ "${#GIT_REPOS_TO_UPDATE[@]}" != "0" ]; then
        _all-up-header "repos"
        git-update-repos
        echo

        _all-up-header "repo branches and stashes"
        git-update-repos -i
        echo
    fi

    if [ -e "${HOME}/.bash_profile" ]; then
        _all-up-header ".bash_profile"
        # shellcheck disable=SC1091
        . "${HOME}/.bash_profile"
        echo
    fi

    # See system_setup.post.sh
    if [ -e "$SYSTEM_SETUP" ]; then
        # See git.post.sh
        _all-up-header ".gitconfig"
        git-config-refresh
        git-config-check
        echo

        if [ -e "${HOME}/.vscode" ]; then
            # See vscode.post.sh
            _all-up-header "Visual Studio Code"
            vscode-check-config
            echo
        fi
    fi

    # Not defined; locally-specific
    # (Intended for things like cluster-credential updates)
    if is_available kube-up; then
        _all-up-header "Kubernetes"
        kube-up
        echo
    fi

    # See above
    _all-up-header "homedir perms"
    fix-homedir-perms
    echo
}
