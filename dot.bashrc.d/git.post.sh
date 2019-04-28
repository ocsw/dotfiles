#!/usr/bin/env bash

git-current-branch () {
    git branch | sed -n '/^\* /  s/^..//p'
}

# Git repo collection; see _git-update-repos-usage()
GIT_REPOS_TO_UPDATE=(
    ".vim/bundle/*|RO"
    ".vim/vim-pathogen|RO"
    ".dotfiles"
    ".pypvutil"
    "sysadmin-notes"
)

_git-update-repos-usage () {
    cat 1>&2 <<EOF
Usage:
GIT_REPOS_TO_UPDATE=(REPO REPO REPO ...)
git-update-repos [-r REPOLIST] [-e EXCLUSIONS] [-s | --silent] [-q | --quiet]
                 [-v | --verbose] [-h | --help]

This tool updates a list of local git repos:
- 'master' and 'develop' branches will be pulled and pushed if present
- Forked repos will be detected by the presence of an 'upstream' remote, and
  the fork's 'master' branch will be updated from the original repo's (pull and
  push to the fork; the original will not be pushed to)
- Repos that are not currently quiescent (nothing in git status) will be
  skipped with warnings

It will also print information about 'extra' branches (not 'master' or
'develop') and stashes.

By default, it uses the GIT_REPOS_TO_UPDATE array (which should not be exported
or prepended to the command line) to determine which repos to update.  The
elements in this array are local filesystem paths.  Each path:
- Must be either absolute or relative to $HOME
- Must not contain whitespace
- Can contain shell patterns (globs)
Each path may also have options appended to it after a '|':
- '|RO' to skip push
Globs and pipes ('|') in entries must be quoted or escaped.

Main options:
    -r REPOLIST
        Overrides the GIT_REPOS_TO_UPDATE array; REPOLIST is a string of
        whitespace-separated repo entries.

    -e EXCLUSIONS
        Filters out repo names from the GIT_REPOS_TO_UPDATE array or -r
        REPOLIST; EXCLUSIONS is string of whitespace-separated patterns (basic
        regexes).  Matching is performed after any globs in the repo list are
        expanded.

    -h | --help
        Prints this help text.

There are 4 levels of verbosity, which cumulatively add outputs:
    -s | --silent
        Print only errors and warnings
    -q | --quiet
        Also print extra branches and stashes
    (default)
        Also print output from git commands
    -v | --verbose
        Also print repo and branch headers even if not doing anything
EOF
}

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
    local stash_list

    local VERB_SILENT=0
    local VERB_QUIET=1
    local VERB_DEFAULT=2
    local VERB_VERBOSE=3

    repo_entries=("${GIT_REPOS_TO_UPDATE[@]}")
    exclusions=()
    verbosity="$VERB_DEFAULT"
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
                verbosity="$VERB_VERBOSE"
                shift
                ;;
            -q|--quiet)
                verbosity="$VERB_QUIET"
                shift
                ;;
            -s|--silent)
                verbosity="$VERB_SILENT"
                shift
                ;;
            -h|--help)
                _git-update-repos-usage
                exit 0
                shift
                ;;
            *)
                _git-update-repos-usage
                exit 1
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

    # apply exclusions (can be grep regexes; matched against full path)
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

        if ! [ -d "$repo" ]; then
            echo "WARNING: Repo not found or not a directory; skipping ($repo)." 1>&2
            cd - || return $?
            continue
        fi

        if [ "$verbosity" -ge "$VERB_VERBOSE" ]; then
            printf "%s\n" "Repo: $repo"
            rstr=""
        else
            rstr=" ($repo)"
        fi
        cd "$repo" || continue

        if [ -n "$(git status --porcelain)" ]; then
            echo "WARNING: Git status not empty; skipping this repo${rstr}." \
                1>&2
            cd - || return $?
            continue
        fi
        starting_branch=$(git-current-branch)
        if [ -z "$starting_branch" ]; then
            # shellcheck disable=SC2140
            echo "WARNING: Can't get current branch; skipping this "\
"repo${rstr}." 1>&2
            cd - || return $?
            continue
        fi

        for branch in develop master; do
            # ignore missing branches
            git branch | \
                grep "^[* ] ${branch}\$" > /dev/null || continue

            # checkout
            [ "$verbosity" -ge "$VERB_VERBOSE" ] && \
                printf "%s\n" "Branch: $branch"
            # only drops stdout because of order
            if git checkout "$branch" 2>&1 > /dev/null | \
                    grep -vE '^(Already on|Switched to branch)'; then
                continue
            fi

            # pull
            if [ "$verbosity" -ge "$VERB_DEFAULT" ]; then
                git pull 2>&1 | grep -v '^Already up to date'
            else
                # only drops stdout because of order
                git pull 2>&1 > /dev/null | grep -v '^Already up to date'
            fi

            # update fork
            # note hardcoded tab
            if [ "$branch" = "master" ] && \
                    git remote -v | \
                    grep '^upstream[ 	].*(fetch)$' > /dev/null; then
                git fetch upstream
                if [ "$verbosity" -ge "$VERB_DEFAULT" ]; then
                    git merge upstream/master 2>&1 \
                        | grep -v '^Already up to date'
                else
                    # only drops stdout because of order
                    git merge upstream/master 2>&1 > /dev/null \
                        | grep -v '^Already up to date'
                fi
            fi

            # push
            if [ "$read_only" = "no" ]; then
                if [ "$verbosity" -ge "$VERB_DEFAULT" ]; then
                    git push 2>&1 | grep -v '^Everything up-to-date'
                else
                    # only drops stdout because of order
                    git push 2>&1 > /dev/null | grep -v '^Everything up-to-date'
                fi
            fi

            # go back to previous branch
            # only drops stdout because of order
            if git checkout "$starting_branch" 2>&1 > /dev/null | \
                    grep -vE '^(Already on|Switched to branch)'; then
                continue
            fi

        done

        if [ "$verbosity" -ge "$VERB_QUIET" ]; then
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
                printf "%s\n" "$stash_list" | sed 's/^/  /'
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
        echo "ERROR: Missing fork_url." 1>&2
        return 1
    fi
    if [ -z "$upstream_url" ]; then
        echo "ERROR: Missing upstream_url." 1>&2
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
