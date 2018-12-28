#!/usr/bin/env bash

git-current-branch () {
    git branch | sed -n '/^*\ /  s/^..//p'
}

# Git repo collection
# - paths must be either absolute or relative to $HOME
# - globs must be quoted or escaped
# - prepend 'RO|' to skip push
# - master and develop branches will be updated (pull/push) if present
GIT_REPOS_TO_UPDATE=(
    # "RO|.vim/bundle/*"
    # "RO|.vim/vim-pathogen"
    ".dotfiles"
    ".pypvutil"
    "sysadmin-notes"
)

git-update-repos () {
    local quiet="$1"

    starting_dir="$PWD"
    trap 'cd "$starting_dir"' RETURN
    cd "${HOME}" || return $?

    # repos with one (master) branch, read only
    # shellcheck disable=SC2068
    for repo in ${GIT_RO_REPOS[@]}; do
        [ -d "$repo" ] || continue  # ignore missing repos
        printf "%s\n" "Repo: $repo"
        cd "$repo" || continue
        git pull 2>&1 | grep -v 'Already up to date'
        cd - || return $?
    done

    # repos with multiple branches, read/write; update master and develop
    # shellcheck disable=SC2068
    for repo in ${GIT_REPOS_TO_UPDATE[@]}; do
        [ -d "$repo" ] || continue  # ignore missing repos
        if [ -z "$quiet" ]; then
            printf "%s\n" "Repo: $repo"
            rstr=""
        else
            rstr=" ($repo)"
        fi
        cd "$repo" || continue
        if [ -n "$(git status --porcelain)" ]; then
            echo "WARNING: Git status not empty; skipping this repo${rstr}."
            cd - || return $?
            continue
        fi
        starting_branch=$(git-current-branch)
        if [ -z "$starting_branch" ]; then
            echo "WARNING: Can't get current branch; skipping this repo${rstr}."
            cd - || return $?
            continue
        fi
        for branch in develop master; do
            # ignore missing branches
            git branch 2>/dev/null |
                grep "^[* ] ${branch}\$" > /dev/null 2>&1 || continue
            [ -z "$quiet" ] && printf "%s\n" "Branch: $branch"
            git checkout "$branch" > /dev/null 2>&1 || continue
            git pull 2>&1 | grep -v 'Already up to date'
            git push 2>&1 | grep -v 'Everything up-to-date'
            git checkout "$starting_branch" > /dev/null 2>&1 || return $?
        done
        extra_branches=$(git branch 2>/dev/null |
            grep -vE "^[* ] (develop|master)\$")
        if [ -n "$extra_branches" ]; then
            echo "Extra branches${rstr}:"
            printf "%s\n" "$extra_branches"
        fi
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
