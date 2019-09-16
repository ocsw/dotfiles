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

# check for component of $PATH itself
is_path_component () {
    [[ $PATH =~ (^|:)$1(:|$) ]]
}
