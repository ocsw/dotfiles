#!/usr/bin/env bash

# --- tools needed for both main body and sub-scripts ---

# shellcheck disable=SC1090  # seems to cover the whole file?
. "${HOME}/.bashrc.d/common.sh"


# --- pre-profile sub-scripts ---

if compgen -G "${HOME}/.bash_profile.d/*.pre.sh" > /dev/null 2>&1; then
  for i in "${HOME}"/.bash_profile.d/*.pre.sh; do
    # shellcheck disable=SC1090
    . "$i"
  done
fi


# --- global environment settings ---

umask 077

if ! is_path_component "${HOME}/bin"; then
  # should probably be at the end, but...
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

if compgen -G "${HOME}/.bash_profile.d/*.post.sh" > /dev/null 2>&1; then
  for i in "${HOME}"/.bash_profile.d/*.post.sh; do
    # shellcheck disable=SC1090
    . "$i"
  done
fi


# --- source .bashrc ---
# shellcheck disable=SC1090
[ -e "${HOME}/.bashrc" ] && . "${HOME}/.bashrc"
