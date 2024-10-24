#!/usr/bin/env bash

# --- tools used in both .bash_profile and .bashrc (and their modules) ---

# note: if we define or include these only in .bash_profile, sub-shells won't
# get them

# check for availability of a command (or commands);
# searches both the PATH and functions
# see also https://github.com/koalaman/shellcheck/wiki/SC2230
is_available () {
    hash "$@" > /dev/null 2>&1
}

# check for a command (or commands) in the PATH, not including aliases or
# functions; may not be 100% portable
# note: I can't find a way to get a portable equivalent of 'which' from Bash
# builtins, but 'command' can at least be used to run a command bypassing
# aliases and functions
in_path () {
    local cmd
    # don't rely on 'which' accepting multiple commands to search for
    for cmd in "$@"; do
        # shellcheck disable=SC2230
        if ! which "$cmd" > /dev/null 2>&1; then
            return 1
        fi
    done
    return 0
}

# check for component of $PATH itself
is_path_component () {
    [[ $PATH =~ (^|:)$1(:|$) ]]
}


# wrap a command in a umask setting;
# use this from a function instead of an alias so it can't be accidentally
# disabled with \cmd
# also, it's generally best to define that function even if the command in
# question isn't installed; that way, when we install it, we don't have to
# restart the shell to get the function (or forget to)
umask_wrap () {
    local mask="$1"
    local cmd="$2"
    local reset_umask
    local rv

    if [ -z "$mask" ]; then
        echo "ERROR: No umask value given." 1>&2
        return 1
    fi
    if ! [[ $mask =~ ^[0-7]{1,4}$ ]]; then
        printf "%s\n" "ERROR: Given umask value '$mask' is invalid." 1>&2
        return 1
    fi
    if [ -z "$cmd" ]; then
        echo "ERROR: No command name given." 1>&2
        return 1
    fi
    shift
    shift

    reset_umask=$(umask -p)

    umask "$mask"
    # since this function is intended to be used in drop-in replacement
    # functions for commands, we have to bypass aliases and functions when
    # calling $cmd, or else we might be calling ourself
    command "$cmd" "$@"
    rv="$?"
    $reset_umask

    return "$rv"
}


# wrap a command in set -x
xtrace_wrap () {
    if [ -z "$1" ]; then
        echo "ERROR: No command given to wrap." 1>&2
        return 1
    fi
    # don't save the current setting, because you wouldn't use this unless it's
    # currently off
    set -x
    "$@"
    rv="$?"
    set +x
    return "$rv"
}
# includes commands, functions and aliases
complete -c xtrace_wrap
