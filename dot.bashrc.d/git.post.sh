#!/usr/bin/env bash

git-current-branch () {
    git branch | sed -n '/^*\ /  s/^..//p'
}

# Git repo collection
# - paths must be either absolute or relative to $HOME
# - paths must not contain whitespace
# - shell patterns (globs) are allowed but must be quoted or escaped
# - append '|RO' to a repo to skip push (must be quoted or escaped)
# - master and develop branches will be updated (pull/push) if present
GIT_REPOS_TO_UPDATE=(
    ".vim/bundle/*|RO"
    ".vim/vim-pathogen|RO"
    ".dotfiles"
    ".pypvutil"
    "sysadmin-notes"
)

git-update-repos () (  # subshell
    # Originally, I saved the starting directory, and went pack to it with a
    # trap.  But the trap command is global, and resetting it from within the
    # trap handler doesn't seem to work.  Running within a subshell avoids all
    # of that.

    local repo_entries
    local verbose
    local expanded_entries
    local entry
    local repo
    local flags
    local exp_repo
    local read_only
    local rstr
    local starting_branch
    local branch
    local extra_branches

    repo_entries=("${GIT_REPOS_TO_UPDATE[@]}")
    verbose="no"
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -r|--repos)
                # shellcheck disable=SC2206
                repo_entries=($2)  # no quotes so we get word splitting
                shift
                shift
                break
                ;;
            -v|--verbose)
                verbose="yes"
                shift
                break
                ;;
            *)
                shift
                break
                ;;
        esac
    done

    cd "${HOME}" || return $?

    # expand globs in the input so we can apply flags separately
    expanded_entries=()
    for entry in "${repo_entries[@]}"; do
        repo="${entry%%|*}"  # might actually be a pattern
        flags="${entry##*|}"
        for exp_repo in $repo; do  # no quotes so it expands
            expanded_entries+=("${exp_repo}|${flags}")
        done
    done

    for entry in "${expanded_entries[@]}"; do
        repo="${entry%%|*}"
        flags="${entry##*|}"
        read_only="no"
        [ "$flags" = "RO" ] && read_only="yes"

        [ -d "$repo" ] || continue  # ignore missing repos
        if [ "$verbose" = "yes" ]; then
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
            git branch 2>/dev/null | \
                grep "^[* ] ${branch}\$" > /dev/null 2>&1 || continue
            [ "$verbose" = "yes" ] && printf "%s\n" "Branch: $branch"
            git checkout "$branch" > /dev/null 2>&1 || continue
            git pull 2>&1 | grep -v 'Already up to date'
            if [ "$read_only" = "no" ]; then
                git push 2>&1 | grep -v 'Everything up-to-date'
            fi
            git checkout "$starting_branch" > /dev/null 2>&1 || return $?
        done

        extra_branches=$(git branch 2>/dev/null | \
            grep -vE "^[* ] (develop|master)\$")
        if [ -n "$extra_branches" ]; then
            echo "Extra branches${rstr}:"
            printf "%s\n" "$extra_branches"
        fi

        cd - || return $?
    done
)

git-clone-fork () {
    local fork_url="$1"
    local upstream_url="$2"
    local fork_user
    local fork_repo

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
