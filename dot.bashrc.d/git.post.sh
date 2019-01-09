#!/usr/bin/env bash

git-current-branch () {
    git branch | sed -n '/^*\ /  s/^..//p'
}

# Git repo collection
# - paths must be either absolute or relative to $HOME
# - paths must not contain whitespace
# - shell patterns (globs) are allowed but must be quoted or escaped
# - options can be appended to repo entries with '|':
#   - '|RO' to skip push
# - globs and pipes ('|') must be quoted or escaped
# - 'master' and 'develop' branches will be updated (pull/push) if present
# - forked repos will be detected, and the fork's 'master' branch will be
#   updated from the original repo's (pull/push to the fork; the original will
#   not be pushed to)
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
    local exclusions
    local verbosity
    local expanded_entries
    local entry
    local repo
    local flags
    local exp_repo
    local filtered_entries
    local matched
    local exclusion
    local read_only
    local rstr
    local starting_branch
    local branch
    local extra_branches

    repo_entries=("${GIT_REPOS_TO_UPDATE[@]}")
    verbosity="2"
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -r|--repos)
                # shellcheck disable=SC2206
                repo_entries=($2)  # no quotes so we get word splitting
                shift
                shift
                ;;
            -e|--exclude)
                # shellcheck disable=SC2206
                exclusions=($2)  # no quotes so we get word splitting
                shift
                shift
                ;;
            -v|--verbose)
                verbosity="3"
                shift
                ;;
            -q|--quiet)
                verbosity="1"
                shift
                ;;
            -s|--silent)
                verbosity="0"
                shift
                ;;
            *)
                shift
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

    # apply exclusions
    filtered_entries=()
    for entry in "${expanded_entries[@]}"; do
        repo="${entry%%|*}"
        flags="${entry##*|}"
        matched="no"
        for exclusion in "${exclusions[@]}"; do
            if printf "%s\n" "$repo" | grep "$exclusion" > /dev/null; then
                matched="yes"
                break
            fi
        done
        if [ "$matched" = "no" ]; then
            filtered_entries+=("${repo}|${flags}")
        fi
    done

    for entry in "${filtered_entries[@]}"; do
        repo="${entry%%|*}"
        flags="${entry##*|}"
        read_only="no"
        [ "$flags" = "RO" ] && read_only="yes"

        [ -d "$repo" ] || continue  # ignore missing repos
        if [ "$verbosity" -ge 3 ]; then
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
            git branch | \
                grep "^[* ] ${branch}\$" > /dev/null || continue

            # checkout
            [ "$verbosity" -ge 3 ] && printf "%s\n" "Branch: $branch"
            # only drops stdout because of order
            if git checkout "$branch" 2>&1 > /dev/null | \
                    grep -v '^Already on'; then
                continue
            fi

            # pull
            if [ "$verbosity" -ge 2 ]; then
                git pull 2>&1 | grep -v 'Already up to date'
            else
                # only drops stdout because of order
                git pull 2>&1 > /dev/null | grep -v 'Already up to date'
            fi

            # update fork
            if [ "$branch" = "master" ] && \
                    git remote -v | \
                    grep '^upstream[ 	].*(fetch)$' > /dev/null; then
                git fetch upstream
                if [ "$verbosity" -ge 2 ]; then
                    git merge upstream/master 2>&1 | grep -v 'Already up to date'
                else
                    # only drops stdout because of order
                    git merge upstream/master 2>&1 > /dev/null \
                        | grep -v 'Already up to date'
                fi
            fi

            # push
            if [ "$read_only" = "no" ]; then
                if [ "$verbosity" -ge 2 ]; then
                    git push 2>&1 | grep -v 'Everything up-to-date'
                else
                    # only drops stdout because of order
                    git push 2>&1 > /dev/null | grep -v 'Everything up-to-date'
                fi
            fi

            # go back to previous branch
            # only drops stdout because of order
            if git checkout "$starting_branch" 2>&1 > /dev/null | \
                    grep -v '^Already on'; then
                continue
            fi

        done

        if [ "$verbosity" -ge 1 ]; then
            # extra branches
            extra_branches=$(git branch | \
                grep -vE "^[* ] (develop|master)\$")
            if [ -n "$extra_branches" ]; then
                echo "Extra branches${rstr}:"
                printf "%s\n" "$extra_branches"
            fi

            # stashes
            stash_list=$(git stash list)
            if [ -n "$stash_list" ]; then
                echo "Stashes${rstr}:"
                printf "%s\n" "$stash_list"
            fi
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
    git-update-repos -r "$(pwd)" "$@"
}
