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
