#!/usr/bin/env bash

# Update All The Things

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
        "${setup_repo}/unix-common/git-config.sh"
        "${setup_repo}/unix-common/git-check.sh"
        echo

        if [ -d "${HOME}/.vscode" ]; then
            _all-up-header "VSCode"
            vscode-check-config
            echo
        fi
    fi

    _all-up-header "perms"
    chmod -R go-rwx "$HOME" 2>&1 | grep -v '/Library/'  # macOS annoyance
    echo
}
