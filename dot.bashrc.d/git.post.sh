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
    "repos/*"  # includes dotfiles and pypvutil
)

_git-update-repos-usage () {
    cat 1>&2 <<EOF
Usage:
GIT_REPOS_TO_UPDATE=(REPO REPO REPO ...)
git-update-repos [-r REPOLIST | --repos REPOLIST]
                 [-e EXCLUSIONS | --exclude EXCLUSIONS]
                 [-k KEYBRANCHLIST | --key KEYBRANCHLIST] [-i | --info-only]
                 [-s | --silent] [-q | --quiet] [-v | --verbose]
                 [-g | --gitverbose] [-h | --help]

This tool updates a list of local git repos, with special treatment of
particular 'key' branches.  Repos that are not currently quiescent (nothing in
git status) will be skipped with warnings, otherwise:

- All configured remotes will be fetched
- Local key branches, if present, will be merged into from their remote
  branches, if present
- Forked repos will be detected by the presence of an 'upstream' remote, and
  the local key branches, if present, will be merged into from their upstream
  branches, if present
- Local key branches, if present, will be pushed back to their remotes

It will also print information about 'extra' (non-'key') branches and stashes.
(Unless --silent is used; see below.  See also --info-only.)

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
    -r REPOLIST | --repos REPOLIST
        Override the GIT_REPOS_TO_UPDATE array; REPOLIST is a string of
        whitespace-separated repo entries.

    -e EXCLUSIONS | --exclude EXCLUSIONS
        Filter out repo names from the GIT_REPOS_TO_UPDATE array or -r REPOLIST;
        EXCLUSIONS is string of whitespace-separated patterns (basic regexes).
        Matching is performed after any globs in the repo list are expanded.

    -k KEYBRANCHLIST | --key KEYBRANCHLIST
        Specify which branches get special treatment; KEYBRANCHLIST is a string
        of whitespace-separated branch names.  It defaults to:
            "master main develop"

    -i | --info-only
        Only print information about extra branches and stashes; do no fetching,
        merging, or pushing.  Implies --quiet (see below).  Does not require
        repos to be quiescent.

    -h | --help
        Print this help text.

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
        Also tell git to be verbose for fetch, merge, and push
EOF
}

git-update-repos () (  # subshell
    # Originally, I saved the starting directory, and went pack to it with a
    # trap.  But the trap command is global, and resetting it from within the
    # trap handler doesn't seem to work.  Running within a subshell avoids all
    # of that.

    local repo_entries
    local exclusions
    local key_branches
    local verbosity
    local info_only
    local key_branches_grep
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
    local bstr
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
    key_branches=("master" "main" "develop")
    verbosity="$VERB_DEFAULT"
    info_only="no"
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
            -k|--key)
                # shellcheck disable=SC2206
                key_branches=($2)  # no quotes so we get word splitting
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
            -i|--info-only)
                info_only="yes"
                shift
                ;;
            -h|--help)
                _git-update-repos-usage
                exit 0
                ;;
            *)
                _git-update-repos-usage
                exit 1
                ;;
        esac
    done

    # put together a string of |-separated key-branch names, for use with grep
    key_branches_grep=""
    for branch in "${key_branches[@]}"; do
        key_branches_grep="${key_branches_grep}|${branch}"
    done
    key_branches_grep="${key_branches_grep##|}"

    # --info implies --quiet, regardless of other options that may have come
    # after it
    if [ "$info_only" = "yes" ]; then
        verbosity="$VERB_QUIET"
    fi

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

        # check for repo and cd
        if ! [ -d "$repo" ]; then
            msg="WARNING: Repo not found or not a directory; skipping ($repo)."
            printf "%s\n" "$msg" 1>&2
            continue
        fi
        cd "$repo" || continue

        # repo name
        if [ "$verbosity" -ge "$VERB_VERBOSE" ]; then
            printf "%s\n" "Repo: $repo"
            rstr=""
        else
            rstr=" ($repo)"
        fi

        if [ "$info_only" == "yes" ]; then
            # check for quiescence, just as information
            if [ -n "$(git status --porcelain)" ]; then
                printf "%s\n" "Git status not empty${rstr}"
            fi
        else
            # check for quiescence and warn / skip
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
                msg="WARNING: Can't get current branch or not on a local "
                msg+="branch; skipping this repo${rstr}."
                printf "%s\n" "$msg" 1>&2
                cd - || return $?
                continue
            fi

            # handle key branches specially
            for branch in "${key_branches[@]}"; do
                # ignore missing branches
                # note: I think this might be safer than
                #     git branch --no-color | \
                #         grep "^[* ] ${branch}\$" > /dev/null
                git show-ref --verify -q "refs/heads/$branch" || continue

                # branch name
                if [ "$verbosity" -ge "$VERB_VERBOSE" ]; then
                    printf "%s\n" "Branch: $branch"
                    bstr=""
                else
                    bstr=" '$branch'"
                fi

                # checkout branch
                # note: only drops stdout because of order
                if git checkout "$branch" 2>&1 > /dev/null | \
                        grep -vE '^(Already on|Switched to branch)'; then
                    continue
                fi

                # merge from remote-tracking branch
                # note: we're assuming that if the branch has remote and merge
                # configs, they point to something included in the remote's
                # fetch config
                if git config --get "branch.${branch}.remote" > /dev/null && \
                        git config --get "branch.${branch}.merge" \
                        > /dev/null; then
                    if [ -n "$git_verb_str" ]; then
                        git merge --ff-only "$git_verb_str"
                    else
                        git merge --ff-only 2>&1 | \
                            grep -vE '^Already up to date|is up to date.$'
                    fi
                else
                    msg="WARNING: Branch${bstr} has no remote configured."
                    printf "%s\n" "$msg" 1>&2
                fi

                # update fork
                # note: we're making some assumptions here:
                # - if there is an upstream fetch config, it includes $branch
                # - if upstream/$branch exists, we want to merge it
                if git config --get remote.upstream.fetch > /dev/null; then
                    # ok, there's an upstream; is there an upstream/$branch?
                    if git show-ref --verify -q \
                            "refs/remotes/upstream/${branch}"; then
                        # merge upstream branch into fork's branch (which we're
                        # on); the push after this section will update the
                        # fork's remote
                        if [ -n "$git_verb_str" ]; then
                            git merge --ff-only "upstream/${branch}" \
                                "$git_verb_str"
                        else
                            git merge --ff-only "upstream/${branch}" 2>&1 \
                                | grep -vE '^Already up to date|is up to date.$'
                        fi
                    else
                        msg="WARNING: There's an upstream remote for this "
                        msg+="repo${rstr}, but no upstream/${branch}."
                        printf "%s\n" "$msg" 1>&2
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
                #
                # (should probably be outside the key-branches loop, but this
                # way, you're never more than a 'git checkout -' away from where
                # you were, no matter at what point in the script it might be
                # killed)
                #
                # only drops stdout because of order
                if git checkout "$starting_branch" 2>&1 > /dev/null | \
                        grep -vE '^(Already on|Switched to branch)'; then
                    continue
                fi
            done  # end of key-branches loop
        fi  # end of if-info-only conditional

        if [ "$verbosity" -ge "$VERB_QUIET" ]; then
            # print extra branches
            # note: this will fail "open" if the format ever changes (i.e. it
            # will just print more than intended)
            # an alternative (but slower) approach would be:
            #   extra_branches=$(git show-ref --heads | awk '{print $2}' | \
            #       sed 's|^refs/heads/||' | \
            #       grep -vE '^(${key_branches_grep})$')
            # and then more processing to add the * to the current branch, and
            # the leading spaces
            extra_branches=$(git branch --no-color | \
                grep -vE "^[* ] (${key_branches_grep})\$")
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
    done  # end of repos loop
)

git-update-repo () {
    git-update-repos -r "$(pwd)" "$@"
}


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

    (
        git clone "$fork_url" "${fork_user}-${fork_repo}" && \
        cd "${fork_user}-${fork_repo}" && \
        git remote add upstream "$upstream_url"
    )
}
