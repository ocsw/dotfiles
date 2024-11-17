#!/usr/bin/env bash

# --- tools needed for both main body and sub-scripts ---

:  # noop; prevents shellcheck disable from covering the whole file
# shellcheck disable=SC1091
. "${HOME}/.bashrc.d/common.sh"


# --- first-step sub-scripts ---

# Brew, in particular, needs to come before anything else so that some of the
# tests in pre-profile scripts have their commands available

while IFS= read -r file; do
    # shellcheck disable=SC1090
    . "$file"
done < <(compgen -G "${HOME}/.bash_profile.d/*.first.sh")


# --- pre-profile sub-scripts ---

# In particular, anything that prepends to the $PATH should be in here, so that
# ~/bin goes before it (see below)

while IFS= read -r file; do
    # shellcheck disable=SC1090
    . "$file"
done < <(compgen -G "${HOME}/.bash_profile.d/*.pre.sh")


# --- global environment settings ---

umask 077

if ! is_path_component "${HOME}/bin" && [ -d "${HOME}/bin" ]; then
    export PATH="${HOME}/bin:${PATH}"
fi

export EDITOR="vim"
export VISUAL="vim"
export PAGER="less -E"

# see also $DIRPAGER and more and lessx aliases in .bashrc
# note: use of '?a .' gets around %t being broken
export LESS='-QRX -Ps?m(%i/%m).?f?a .%f.?e?a .(END):?pB?a .%pB\%..?c?a .[Col %c].?e?x - Next\: %x.%t$'
export LESSHISTFILE="/dev/null"

export MANPAGER="less -F"
# note: \% and \: from original prompt don't need extra \ in bash
# shellcheck disable=SC2016
export MANOPT='-r ?m(%i/%m).?a\ .Manual\ page\ \$MAN_PN?e?a\ .(END):?pB?a\ .%pB\%..?c?a\ .[Col\ %c].?e?x\ -\ Next\:\ %x.%t'

if [ -n "$PS1" ]; then
    export MAIL="/var/mail/$USER"
    [ -t 0 ] && mesg n
fi


# --- post-profile sub-scripts ---

while IFS= read -r file; do
    # shellcheck disable=SC1090
    . "$file"
done < <(compgen -G "${HOME}/.bash_profile.d/*.post.sh")


# --- source .bashrc ---

# shellcheck disable=SC1091
[ -e "${HOME}/.bashrc" ] && . "${HOME}/.bashrc"
