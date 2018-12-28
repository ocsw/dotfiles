#!/usr/bin/env bash

git-current-branch () {
    git branch | sed -n '/^*\ /  s/^..//p'
}

git-update-repos () {
    start_dir="$PWD"
    trap 'cd "$start_dir"' RETURN

    own_repos="
        .dotfiles
        .pypvutil
        sysadmin-notes
    "
    cd "${HOME}" || return $?
    for i in $own_repos; do
        [ -d "$i" ] || continue
        cd "$i" || continue
        printf "%s\n" "Repo: $i"
        if [ -z "$(git status --porcelain)" ]; then
            git pull 2>&1 | grep -v 'Already up to date'
            git push 2>&1 | grep -v 'Everything up-to-date'
        else
            echo "WARNING: Git status not empty; skipping this repo."
        fi
        cd - || return $?
    done

    # vim stuff
    cd "${HOME}/.vim" || return $?
    for i in vim-pathogen bundle/*; do
        cd "$i" || continue
        printf "%s\n" "Repo: $i"
        git pull 2>&1 | grep -v 'Already up to date'
        cd - || return $?
    done
}

git-clone-fork () {
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

git-update-fork () {
    git fetch upstream || return $?
    git checkout master || return $?
    git pull || return $?
    git merge upstream/master || return $?
    git push
}
