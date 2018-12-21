#!/usr/bin/env bash

clone-fork () {
    local fork_url="$1"
    local upstream_url="$2"

    if [ -z "$fork_url" ]; then
        echo "ERROR: Missing fork_url."
        return 1
    fi
    if [ -z "$upstream_url" ]; then
        echo "ERROR: Missing upstream_url."
        return 1
    fi

    fork_user=$(printf "%s\n" "$fork_url" | awk -F/ '{print $(NF-1)}' | \
        sed 's/^.*://')
    fork_repo=$(printf "%s\n" "$fork_url" | awk -F/ '{print $(NF)}' | \
        sed 's/\.git$//')

    git clone "$fork_url" "${fork_user}-${fork_repo}" || return $?
    cd "${fork_user}-${fork_repo}" || return $?
    git remote add upstream "$upstream_url" || return $?
    # shellcheck disable=SC2164
    cd -
}

update-fork () {
    git fetch upstream || return $?
    git co master || return $?
    git pull || return $?
    git merge upstream/master || return $?
    git push
}
