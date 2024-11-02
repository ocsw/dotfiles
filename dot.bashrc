#!/usr/bin/env bash

# --- setup ---

# stop if shell is non-interactive
# (note: bash 4 reads .bashrc even if non-interactive)
[ -z "$PS1" ] && return

# what OS are we on?
OS_UNAME=$(uname)
[ -z "$OS_UNAME" ] && OS_UNAME="unknown"

# start P_C from scratch
# also prevents duplication if we re-source the file
unset PROMPT_COMMAND

# tools needed for both main body and sub-scripts
# shellcheck disable=SC1091
. "${HOME}/.bashrc.d/common.sh"


# --- pre-rc sub-scripts ---

while IFS= read -r file; do
    # shellcheck disable=SC1090
    . "$file"
done < <(compgen -G "${HOME}/.bashrc.d/*.pre.sh")


# --- shell options ---

# history settings
HISTFILESIZE=""  # unlimited
HISTSIZE=""  # unlimited
HISTCONTROL="ignoredups"
HISTIGNORE="bg:bg *:fg:fg *"
# see h(), below
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ; }h -a -t"
shopt -s cmdhist lithist  # and use C-xC-e to edit
shopt -s histappend histverify
#shopt -s histreedit

# completion settings
shopt -s no_empty_cmd_completion
if [ -t 0 ]; then
    bind "set mark-symlinked-directories on"
    bind "set page-completions off"
    bind "set show-all-if-unmodified on"
    #bind "set completion-query-items 1000"
    #bind "set match-hidden-files off"
    #bind "set show-all-if-ambiguous on"
fi

# key bindings
if [ -t 0 ]; then
    bind '"\C-d": delete-char-or-list'
    # see also .inputrc
fi

# misc settings
set -o noclobber
shopt -s checkwinsize
if [ -t 0 ]; then
    bind "set bell-style none"
fi


# --- prompt ---

# mark at the end of the prompt
if [ "$EUID" -eq 0 ]; then
    PS1_MK="#"
else
    PS1_MK='$'
fi

# are we in mosh, tmux, and/or screen?
SELF_PPID=$(ps -eo pid,ppid | awk "\$1 == $$ {print \$2}")
SELF_PARENT=$(
    ps -eo pid,comm | awk "\$1 == $SELF_PPID {print \$0}" |
        sed 's/^[ 	]*[0-9]*[ 	][ 	]*//'
)
[ "$SELF_PARENT" = "mosh-server" ] && IN_MOSH="yes"
[ -n "$TMUX" ] && IN_TMUX="yes"
[ -z "$TMUX" ] && [ "$TERM" = "screen" ] && IN_SCREEN="yes"

# string of marks, 1 for each level of shell nesting, with corrections
MARKLVL="$SHLVL"
for i in $IN_MOSH $IN_TMUX $IN_SCREEN; do  # no quotes
    MARKLVL=$((MARKLVL - 1))
done
PS1_MARKS=""
for ((i=MARKLVL; i > 0; i--)); do
    PS1_MARKS="$PS1_MK$PS1_MARKS"
done

# add mosh/tmux/screen markers, in order
[ -n "$IN_SCREEN" ] && PS1_MARKS="S$PS1_MARKS"
[ -n "$IN_TMUX" ] && PS1_MARKS="T$PS1_MARKS"
[ -n "$IN_MOSH" ] && PS1_MARKS="M$PS1_MARKS"

# if there are jobs (stopped or running), add a symbol to the prompt
jobs_flag () {
    # bash 4.0 has a bug that prevents the prompt from being printed at all
    # if there's a $() in anything run from PROMPT_COMMAND or PS1;
    # but $() in PS1 itself works, and so does ``
    #
    # terminal \n is stripped by the substitution in PS1, so we don't need
    # to use echo -n or printf
    #
    # shellcheck disable=SC2006
    [ -n "`jobs -p`" ] && echo "."
}

# prompt colors
#
# can change colors later or from the shell; takes effect immediately
# see list below for possible values
#
if [ -n "$LIGHT_BG" ]; then
    #PS1_COLOR=${PS1_COLOR:-34}    # blue
    #
    # white, red, yellow, green, cyan, blue, magenta
    # shellcheck disable=SC2034
    PS1_COLORS=("37" "31" "33" "32" "36" "34" "35")
else
    #PS1_COLOR=${PS1_COLOR:-1;36}  # bright cyan
    #
    # white, bright {red, yellow, green, cyan, blue, magenta}
    # shellcheck disable=SC2034
    PS1_COLORS=("37" "1;31" "1;33" "1;32" "1;36" "1;34" "1;35")
fi

# set the prompt
#
#PS1='\[\e[${PS1_COLOR}m\]\! $PWD @ \h$(jobs_flag)$PS1_MARKS\[\e[0m\] '
#PS1='\[\e[${PS1_COLOR}m\]$(_errorcode_prompt)\! \u@\h $PWD$(_prompt_scm_info)$(jobs_flag)$PS1_MARKS\[\e[0m\] '
#
# NOTE: prompt requires _python_venv_prompt, _errorcode_prompt, and
# _prompt_scm_info to be defined later
#
# 0 and 1 and 4 and 5 are in single strings to avoid having an extra space if a
# component is empty
#
# shellcheck disable=SC2016
PS1_PARTS=(
    '\[\e[${PS1_COLORS[0]}m\]$(_python_venv_prompt)\[\e[0m\]\[\e[${PS1_COLORS[1]}m\][ $(_errorcode_prompt) ]\[\e[0m\]'
    '\[\e[${PS1_COLORS[2]}m\]\!\[\e[0m\]'
    '\[\e[${PS1_COLORS[3]}m\]\u@\h\[\e[0m\]'
    '\[\e[${PS1_COLORS[4]}m\]${PWD}\[\e[0m\]\[\e[${PS1_COLORS[5]}m\]$(_prompt_scm_info " %s")\[\e[0m\]'
    '\[\e[${PS1_COLORS[6]}m\]$(jobs_flag)$PS1_MARKS\[\e[0m\]'
)
PS1="${PS1_PARTS[*]} "
typeset +x PS1  # this is exported on Cygwin for some reason

# -- notes on prompt strings --
#
# PS1 is evaluated before printing, so it can be in single-quotes and still
# contain variables (which is clearer); otherwise, we would have to reset it in
# PROMPT_COMMAND
#
# it can also contain variables set with $'' to include escape chars
# e.g. blue=$'ansi_cmd'; PS1='\[$blue\] bluetext'
# (\[\] have to be in PS1, not blue - see below)
# PS1_COLOR is easier to work with by hand as number(s), though
#
# \[ and \] mark non-printing sequences (so the shell can calculate the length
# of the prompt)
#
# to enter control codes manually, use $' quoting:
# echo $'codes'
# (or ideally printf "%s\n" $'codes')
#
#
# ANSI color codes (partial list):
#
# \e[<param>m where <param> = zero or more of the following, separated with ;
#
# 0        = reset
# 1  or 22 = bold (bright fg)   on or off
# 7  or 27 = negative (inverse) on or off
# 30 or 40 = fg or bg black
# 31 or 41 = fg or bg red
# 32 or 42 = fg or bg green
# 33 or 43 = fg or bg yellow
# 34 or 44 = fg or bg blue
# 35 or 45 = fg or bg magenta
# 36 or 46 = fg or bg cyan
# 37 or 47 = fg or bg white
# 39 or 49 = fg or bg default
#
#
# xterm control codes (partial list):
#
# \e]<1>;<2>\a where <1> and <2> are
#
# 0   string -> change icon name and window title to string
# 1   string -> change icon name to string
# 2   string -> change window title to string
# 4;c spec -> change ANSI color c to spec, where spec is a name or #RGB in hex
#             and c is 0-7 for regular colors, 8-15 for bold
#
# note: see wintitle(), below


# --- aliases & functions ---

# program control aliases (and related shortcuts)
alias nano="nano -z"
alias pico="pico -z"
#
# note: check here to avoid stepping on pico and more, but in general,
# leave aliases in place even if the commands aren't installed;
# shortcuts will give more informative error messages, and control
# aliases will be in place if the user installs the relevant command
#
is_available nano && alias pico=nano
is_available less && alias more="less -E"
alias lessx="less -+X"
if [[ $OS_UNAME =~ CYGWIN.* ]]; then
    explorer () { command explorer ${1:+$(cygpath -wl "$1")}; }
    alias mintty="run mintty -t bash -e env SHLVL=0 bash -l"
    alias brmintty="run mintty -c ~/.minttyrc.bigrev -t bash -e env LIGHT_BG=1 SHLVL=0 bash -l"
    alias traceroute="echo; echo '[Windows tracert]'; tracert"
    alias trg="traceroute -d 8.8.8.8"
else
    alias trg="traceroute -n 8.8.8.8"
fi
if [ "$OS_UNAME" = "Darwin" ]; then
    alias ls="ls -G"
    if is_available gcp brew &&
            [ "$(command -v gcp)" = "$(brew --prefix)/bin/gcp" ]; then
        alias cp="gcp"
    fi
    if is_available gmv brew &&
            [ "$(command -v gmv)" = "$(brew --prefix)/bin/gmv" ]; then
        alias mv="gmv"
    fi
fi

# directory listing shortcuts
#
DIRPAGER="${DIRPAGER:-less -E}"  # don't use with quotes
alias l="ls -alF"  # from OpenBSD defaults
# shellcheck disable=SC2012
d () { ls -l   "$@" 2>&1 | $DIRPAGER; }
# shellcheck disable=SC2012
s () { ls -laR "$@" 2>&1 | $DIRPAGER; }
# shellcheck disable=SC2012
a () { ls -la  "$@" 2>&1 | $DIRPAGER; }
case "$OS_UNAME" in
    CYGWIN*)
        # note: /a is for ASCII; no way to exclude dotfiles
        # dirs, incl. dots
        t () {
            tree.com /a    ${1+"$(cygpath -ml "$1" | sed 's|/$||')"} |
                sed -e '1,2d' -e 's/^[A-Z]:\.$/./' | $DIRPAGER
        }
        # files, incl. dots
        tf () {
            tree.com /a /f ${1+"$(cygpath -ml "$1" | sed 's|/$||')"} |
                sed -e '1,2d' -e 's/^[A-Z]:\.$/./' | $DIRPAGER
        }
        ;;
    OpenBSD)
        t ()   { tree -s -d    "$@" 2>&1 | $DIRPAGER; }  # dirs,  no dots
        tf ()  { tree -s       "$@" 2>&1 | $DIRPAGER; }  # files, no dots
        ta ()  { tree -s -d -a "$@" 2>&1 | $DIRPAGER; }  # dirs,  incl. dots
        tfa () { tree -s    -a "$@" 2>&1 | $DIRPAGER; }  # files, incl. dots
        ;;
    *)
        t ()   { tree --noreport -d    "$@" 2>&1 | $DIRPAGER; }  # d, no .
        tf ()  { tree --noreport       "$@" 2>&1 | $DIRPAGER; }  # f, no .
        ta ()  { tree --noreport -d -a "$@" 2>&1 | $DIRPAGER; }  # d, incl. .
        tfa () { tree --noreport    -a "$@" 2>&1 | $DIRPAGER; }  # f, incl. .
        ;;
esac

# misc shortcuts
wintitle () { printf "\033]0;%s\a" "$*"; }
alias m=mutt  # mailreader; if mutt isn't installed, override in .bashrc.local
alias p=clear
alias j="jobs -l"
# see
# https://stackoverflow.com/questions/17998978/removing-colors-from-output/51141872#51141872
alias decolorize="sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'"

# history list shortcut, with additions
#
# 1) with no arguments, prints the last 20 history entries
# 2) uses the existing value/state of HISTTIMEFORMAT, or accepts -t to
#    include/change timestamps (default '%R  ')
# 3) -t can have a format string added (e.g. '-t%a  ' or -t%a\ \ )
# 4) +t removes timestamps, including any existing HISTTIMEFORMAT
# 5) last -/+t sets format string
# 6) -/+t does not count as an argument for point (1), with or without a string
#    (i.e. h -t still prints 20 entries)
# 7) leaves global HISTTIMEFORMAT unchanged (even with -/+t)
# 8) any non- -/+t arguments are passed to the history builtin
#
h () {
    local h_args=""
    local htf
    local i

    # local copy of HTF, including set/unset/null status
    if [ -n "${HISTTIMEFORMAT+x}" ]; then
        local HISTTIMEFORMAT="$HISTTIMEFORMAT"
    else
        local HISTTIMEFORMAT
        unset HISTTIMEFORMAT  # will still be local if we set it later
    fi

    for i in "$@"; do
        if [ "${i:0:2}" = "-t" ]; then
            htf="${i:2}"
            HISTTIMEFORMAT="${htf:-%R  }"
        elif [ "${i:0:2}" = "+t" ]; then
            unset HISTTIMEFORMAT
        else
            h_args="$h_args $i"  # unnecessary space at the beginning (shrug)
        fi
    done

    # shellcheck disable=SC2086
    builtin history ${h_args:-20}  # no quotes
}

# make cd not print the target directory for "cd -";
cd () {
    if [ "$*" = "-" ]; then
        builtin cd - > /dev/null || return $?
    else
        builtin cd "$@" || return $?
    fi

    # for VSCode, iTerm, probably others; from MongoDB
    if  [ -t 1 ]; then
        printf "%s" $'\e]1337;CurrentDir=$PWD\a'
    fi
}

# move up the directory tree; partly from Simon Elmir
up () {
    local updir
    if [ -z "$1" ]; then
        updir=".."
    else
        updir=$(printf "../%.0s" $(seq 1 "$1"))
    fi
    if [ -t 1 ]; then
        cd "$updir" || return $?
    else
        printf "%s\n" "$updir"
    fi
}

# make bg and fg accept a bare number instead of %num
bg () {
    if [ -n "$1" ]; then
        builtin bg "%$1"
    else
        builtin bg
    fi
}
fg () {
    if [ -n "$1" ]; then
        builtin fg "%$1"
    else
        builtin fg
    fi
}

# glob expansion for commands
#
# takes the place of the missing functionality from tcsh's ^Xg;
# argument will probably need to be quoted
#
# on Cygwin:
# -looks for both pattern and pattern.exe
# -removes *.dll from the results
#
# note: uses $OS_UNAME and requires is_available(), find, sed, and sort
#
gc () {
    # note: bash seems to be inconsistent about whether local declarations with
    # no initializer create unset or null variables
    local cygflag  # starts out unset/null, not 0
    local path="$PATH"
    local IFS
    local i
    local d
    local f
    local list

    # it's important for $list to start out unset; because we declared it local
    # above, it will still be local when we actually use it
    unset list

    if [ -z "$1" ]; then
        echo "Usage: gc 'PATTERN'"
        return
    fi

    # before we start doing anything messy or time consuming...
    if ! is_available find sed sort; then
        echo "Error: gc requires find, sed, and sort available in the path."
        return
    fi

    [[ $OS_UNAME =~ CYGWIN.* ]] && cygflag=1

    # trailing : in $PATH is interpreted as .
    # make it :: so the loop will see it
    # (leading : will already show up)
    [[ $path =~ .*: ]] && path="$path:"

    i=0
    IFS=":"
    for d in $path; do  # no quotes
        [ -z "$d" ] && d="."  # :: or leading : in $path

        # have to reset IFS around this command so ${} results will be split
        # into multiple words
        #
        # have to separate the ^$d and ^/ patterns because dirs with (single)
        # slashes in $path will only get one slash in the output
        #
        # could use ${//} instead of sed but this is more portable (and probably
        # not much slower overall given the heavy use of find)
        #
        # use : as delimiter in sed because it's guaranteed not to be in $d (or
        # else $d would have been split)
        #
        IFS=" "
        f=$(find -H "$d" -maxdepth 1 -mindepth 1 \
            \( -name "$1" ${cygflag:+-o -name "$1.exe"} \) 2>/dev/null |
            sed -e "s:^${d}::" -e "s:^/::" ${cygflag:+-e '/\.dll$/d'})
        IFS=":"
        [ -n "$f" ] && list["$i"]="$f"

        : $(( i++ ))
    done

    # any member of $list that was actually set won't be null, so there won't be
    # blank lines from (e.g.) directories with no results; but the join will
    # produce "" if there were no results at all, so:
    if [ -n "${list[*]}" ]; then
        IFS=$'\n'
        printf "%s\n" "${list[*]}" | sort -u
    fi
}


# --- post-rc sub-scripts ---

while IFS= read -r file; do
    # shellcheck disable=SC1090
    . "$file"
done < <(compgen -G "${HOME}/.bashrc.d/*.post.sh")


# --- machine-specific settings, overrides, aliases, etc. ---

# shellcheck disable=SC1091
[ -e "${HOME}/.bashrc.local" ] && . "${HOME}/.bashrc.local"
