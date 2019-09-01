#!/usr/bin/env bash

git-current () {
    # NOTE: don't use this if you need a branch name you can checkout back to!
    # (this can give you things like '(HEAD detached at origin/master)'; use
    # git-current-branch() instead in that case)
    # see also
    # https://stackoverflow.com/questions/6245570/how-to-get-the-current-branch-name-in-git
    git branch --no-color | sed -n '/^\* /  s/^..//p'
}

git-current-branch () {
    # prints the current branch, or fails with no output if we're not on a
    # local branch (e.g. detached HEAD)
    # see also
    # https://stackoverflow.com/questions/6245570/how-to-get-the-current-branch-name-in-git
    git symbolic-ref --short -q HEAD
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
                 [-v | --verbose] [-g | --gitverbose] [-h | --help]

This tool updates a list of local git repos:
- Repos that are not currently quiescent (nothing in git status) will be
  skipped with warnings, otherwise:
- All configured remotes will be fetched
- Local 'master' and 'develop' branches, if present, will be merged into from
  their remote-tracking branches
- Forked repos will be detected by the presence of an 'upstream' remote, and
  the local 'master' branch, if present, will be merged into from its
  'upstream'-tracking branch
- Local 'master' and 'develop' branches, if present, will be pushed back to
  their remotes

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
    -g | --gitverbose
        Also tell git to be verbose for pull, fetch, merge, and push
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
    local git_verb_str
    local expanded_entries
    local entry
    local repo
    local flags
    local exp_repo
    local filtered_entries
    local matched
    local exclusion
    local read_only
    local msg
    local rstr
    local starting_branch
    local branch
    local extra_branches
    local stash_list

    # verbosity constants
    local VERB_SILENT=0
    local VERB_QUIET=1
    local VERB_DEFAULT=2
    local VERB_VERBOSE=3
    local VERB_GITVERBOSE=4

    # process arguments
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
            -g|--gitverbose)
                verbosity="$VERB_GITVERBOSE"
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

    # process verbosity
    if [ "$verbosity" -ge "$VERB_GITVERBOSE" ]; then
        git_verb_str="-v"
    elif [ "$verbosity" -ge "$VERB_DEFAULT" ]; then
        git_verb_str=""
    else
        git_verb_str="-q"
    fi

    # use $HOME as the basis for relative paths
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

    # loop on repos
    for entry in "${filtered_entries[@]}"; do
        repo="${entry%%|*}"
        flags="${entry##*|}"
        read_only="no"
        [ "$flags" = "RO" ] && read_only="yes"

        # check for repo
        if ! [ -d "$repo" ]; then
            msg="WARNING: Repo not found or not a directory; skipping ($repo)."
            printf "%s\n" "$msg" 1>&2
            cd - || return $?
            continue
        fi

        # repo name
        if [ "$verbosity" -ge "$VERB_VERBOSE" ]; then
            printf "%s\n" "Repo: $repo"
            rstr=""
        else
            rstr=" ($repo)"
        fi
        cd "$repo" || continue

        # check for quiescence
        if [ -n "$(git status --porcelain)" ]; then
            msg="WARNING: Git status not empty; skipping this repo${rstr}."
            printf "%s\n" "$msg" 1>&2
            cd - || return $?
            continue
        fi

        # fetch from all remotes
        if [ -n "$git_verb_str" ]; then
            git fetch --all "$git_verb_str"
        else
            git fetch --all | grep -v '^Fetching '
        fi

        # save starting branch
        if ! starting_branch=$(git symbolic-ref --short -q HEAD); then
            msg="WARNING: Can't get current branch or not on a local branch; "
            msg+="skipping this repo${rstr}."
            printf "%s\n" "$msg" 1>&2
            cd - || return $?
            continue
        fi

        # handle master and develop branches specially
        for branch in master develop; do
            # ignore missing branches
            # note: I think this might be safer than
            #     git branch --no-color | \
            #         grep "^[* ] ${branch}\$" > /dev/null
            git show-ref --verify -q "refs/heads/$branch" || continue

            # checkout
            [ "$verbosity" -ge "$VERB_VERBOSE" ] && \
                printf "%s\n" "Branch: $branch"
            # only drops stdout because of order
            if git checkout "$branch" 2>&1 > /dev/null | \
                    grep -vE '^(Already on|Switched to branch)'; then
                continue
            fi

            # merge from remote-tracking branch
            if [ -n "$git_verb_str" ]; then
                git merge "$git_verb_str"
            else
                git merge 2>&1 | grep -vE '^Already up to date|is up to date.$'
            fi

            # update fork
            if [ "$branch" = "master" ] && \
                    git config --get remote.upstream.fetch > /dev/null; then
                # merge upstream master into fork's master (which we're on); the
                # push after this section will update the fork's remote
                if [ -n "$git_verb_str" ]; then
                    git merge upstream/master "$git_verb_str"
                else
                    git merge upstream/master 2>&1 \
                        | grep -vE '^Already up to date|is up to date.$'
                fi
            fi

            # push
            if [ "$read_only" = "no" ]; then
                if [ -n "$git_verb_str" ]; then
                    git push "$git_verb_str"
                else
                    git push 2>&1 | grep -v '^Everything up-to-date'
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
            # print extra branches
            # note: this will fail "open" if the format ever changes (i.e. it
            # will just print more than intended)
            # an alternative (but slower) approach would be:
            #   extra_branches=$(git show-ref --heads | awk '{print $2}' | \
            #       sed 's|^refs/heads/||' | grep -vE '^(master|develop)$')
            # and then more processing to add the * to the current branch, and
            # the leading spaces
            extra_branches=$(git branch --no-color | \
                grep -vE "^[* ] (develop|master)\$")
            if [ -n "$extra_branches" ]; then
                printf "%s\n" "Extra branches${rstr}:"
                printf "%s\n" "$extra_branches"
            fi

            # print stashes
            stash_list=$(git stash list)
            if [ -n "$stash_list" ]; then
                printf "%s\n" "Stashes${rstr}:"
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
