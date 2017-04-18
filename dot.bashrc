# --- setup ---

# stop if shell is non-interactive
# (note: bash 4 reads .bashrc even if non-interactive)
[[ -z "$PS1" ]] && return

# what OS are we on?
OS_UNAME="$(uname)"
[[ -z "$OS_UNAME" ]] && OS_UNAME=unknown

# start P_C from scratch
# also prevents duplication if we re-source the file
unset PROMPT_COMMAND


# --- shell options ---

# history settings
HISTCONTROL=ignoredups
HISTIGNORE='bg:bg *:fg:fg *'
# see h(), below
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ; }h -a -t"
shopt -s cmdhist lithist  # and use C-xC-e to edit
shopt -s histappend histverify
#unset HISTFILE
#HISTFILESIZE=100
#HISTSIZE=100
#shopt -s histreedit

# completion settings
shopt -s no_empty_cmd_completion
bind 'set mark-symlinked-directories on'
bind 'set page-completions off'
bind 'set show-all-if-unmodified on'
#bind 'set completion-query-items 1000'
#bind 'set match-hidden-files off'
#bind 'set show-all-if-ambiguous on'

# key bindings
bind '"\C-d": delete-char-or-list'
# see also .inputrc

# misc settings
TMPDIR="$HOME"  # for bash, don't export
set -o noclobber
shopt -s checkwinsize
bind 'set bell-style none'


# --- prompt ---

# mark at the end of the prompt
if [[ "$EUID" -eq 0 ]]; then
  PS1_MK='#'
else
  PS1_MK='$'
fi

# string of marks, 1 for each level of shell nesting
PS1_MARKS=''
for ((PS1_DEPTH=SHLVL; PS1_DEPTH > 0; PS1_DEPTH--)); do
  PS1_MARKS="$PS1_MK$PS1_MARKS"
done

# clean up
unset PS1_MK
unset PS1_DEPTH

# if there are jobs (stopped or running), add a symbol to the prompt
jobs_flag() {
  # bash 4.0 has a bug that prevents the prompt from being printed at all
  # if there's a $() in anything run from PROMPT_COMMAND or PS1;
  # but $() in PS1 itself works, and so does ``
  #
  # terminal \n is stripped by the substitution in PS1, so we don't need
  # to use echo -n (and the output is cleaner if run from the command line)
  #
  [[ -n "`jobs -p`" ]] && echo '.'
}

# prompt color
#
# can change this later or from the shell, takes effect immediately
# see list below for possible values
#
if [[ "$LIGHT_BG" -eq 1 ]]; then
  PS1_COLOR=${PS1_COLOR:-34}    # blue
else
  PS1_COLOR=${PS1_COLOR:-1;36}  # bright cyan
fi

# set the prompt
PS1='\[\e[${PS1_COLOR}m\]\! $PWD @ \h$(jobs_flag)$PS1_MARKS\[\e[0m\] '
typeset +x PS1  # this is exported on Cygwin for some reason

# -- notes on prompt strings --
#
# PS1 is evaluated before printing, so it can be in single-quotes and 
# still contain variables (which is clearer); otherwise, we would have to 
# reset it in PROMPT_COMMAND
#
# it can also contain variables set with $'' to include escape chars
# e.g. blue=$'ansi_cmd'; PS1='\[$blue\] bluetext'
# (\[\] have to be in PS1, not blue - see below)
# PS1_COLOR is easier to work with by hand as number(s), though
#
# \[ and \] mark non-printing sequences (so the shell can calculate the 
# length of the prompt)
#
# to enter control codes manually, use $' quoting:
# echo $'codes'
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

# check for command in path
in_path() {
  hash "$@" > /dev/null 2>&1
  return $?
}

# program control aliases (and related shortcuts)
alias nano='nano -z'
alias pico='pico -z'
#
# note: check here to avoid stepping on pico and more, but in general,
# leave aliases in place even if the commands aren't installed;
# shortcuts will give more informative error messages, and control
# aliases will be in place if the user installs the relevant command
#
in_path nano && alias pico=nano
in_path less && alias more='less -E'
alias lessx='less -+X'
if [[ "$OS_UNAME" == CYGWIN* ]]; then
  explorer() { command explorer ${1:+$(cygpath -wl $1)}; }
  alias mintty='run mintty -t bash -e env SHLVL=0 bash -l'
  alias brmintty='run mintty -c ~/.minttyrc.bigrev -t bash -e env LIGHT_BG=1 SHLVL=0 bash -l'
  alias traceroute='echo; echo "[Windows tracert]"; tracert'
  alias trg='traceroute -d 74.125.47.100'  # one of the IPs for google.com
else
  alias trg='traceroute -n 74.125.47.100'
fi

# directory listing shortcuts
#
# [ old note, kept for reference:
# [ (aliases used \more)
# [-any later aliasing of 'more' ordinarily wouldn't affect these because 
# [ aliases are expanded when functions are defined, not executed
# [-but re-sourcing this file afterwards _would_ change the definitions
# [-so, use backslashes
# [-however, making 'more' a function will still change these
#
# ${1+"$@"} isn't really necessary in bash, but it's the portable usage;
# some shells will convert "$@" to "" if there are no arguments
#
DIRPAGER=${DIRPAGER:-less -E}  # don't use with quotes
alias l='ls -alF'  # from OpenBSD defaults
d() { ls -l   ${1+"$@"} 2>&1 | $DIRPAGER; }
s() { ls -laR ${1+"$@"} 2>&1 | $DIRPAGER; }
a() { ls -la  ${1+"$@"} 2>&1 | $DIRPAGER; }
case "$OS_UNAME" in
  CYGWIN*)
    # note: /a is for ASCII; no way to exclude dotfiles
    # dirs,  incl. dots
    t() {
      tree.com /a    ${1+"$(cygpath -ml "$1" | sed 's|/$||')"} | \
        sed -e '1,2d' -e 's/^[A-Z]:\.$/./' | $DIRPAGER
    }
    # files, incl. dots
    tf() {
      tree.com /a /f ${1+"$(cygpath -ml "$1" | sed 's|/$||')"} | \
        sed -e '1,2d' -e 's/^[A-Z]:\.$/./' | $DIRPAGER
    }
    ;;
  OpenBSD)
    t()   { tree -s -d    ${1+"$@"} 2>&1 | $DIRPAGER; }  # dirs,  no dots
    tf()  { tree -s       ${1+"$@"} 2>&1 | $DIRPAGER; }  # files, no dots
    ta()  { tree -s -d -a ${1+"$@"} 2>&1 | $DIRPAGER; }  # dirs,  incl. dots
    tfa() { tree -s    -a ${1+"$@"} 2>&1 | $DIRPAGER; }  # files, incl. dots
    ;;
  *)
    t()   { tree --noreport -d    ${1+"$@"} 2>&1 | $DIRPAGER; }  # d, no .
    tf()  { tree --noreport       ${1+"$@"} 2>&1 | $DIRPAGER; }  # f, no .
    ta()  { tree --noreport -d -a ${1+"$@"} 2>&1 | $DIRPAGER; }  # d, incl. .
    tfa() { tree --noreport    -a ${1+"$@"} 2>&1 | $DIRPAGER; }  # f, incl. .
    ;;
esac

# misc shortcuts
wintitle() {
  # use eval to keep 'set' list from messing up the title
  # (also makes arg substitution/quoting cleaner)
  eval echo "$'\e]0;$*\a'"
}
alias m=mutt  # mailreader; if mutt isn't installed, override in .bashrc.local
alias p=clear
alias j='jobs -l'

# history list shortcut, with additions
# 
# 1) with no arguments, prints the last 20 history entries
# 2) uses the existing value/state of HISTTIMEFORMAT, or accepts -t to 
#    include/change timestamps (default '%R  ')
# 3) -t can have a format string added (e.g. '-t%a  ' or -t%a\ \ )
# 4) +t removes timestamps, including any existing HISTTIMEFORMAT
# 5) last -/+t sets format string
# 6) -/+t does not count as an argument for point (1), with or without a 
#    string (i.e. h -t still prints 20 entries)
# 7) leaves global HISTTIMEFORMAT unchanged (even with -/+t)
# 8) any non- -/+t arguments are passed to the history builtin
#
h() {
  local h_args=''
  local htf
  local i

  # local copy of HTF, including set/unset/null status
  if [[ -n "${HISTTIMEFORMAT+x}" ]]; then
    local HISTTIMEFORMAT="$HISTTIMEFORMAT"
  else
    local HISTTIMEFORMAT
    unset HISTTIMEFORMAT  # will still be local if we set it later
  fi

  for i in "$@"; do
    if [[ "${i:0:2}" == '-t' ]]; then
      htf="${i:2}"
      HISTTIMEFORMAT="${htf:-%R  }"
    elif [[ "${i:0:2}" == '+t' ]]; then
      unset HISTTIMEFORMAT
    else
      h_args="$h_args $i"  # unnecessary space at the beginning (shrug)
    fi
  done

  builtin history ${h_args:-20}  # no quotes
}

# make cd not print the target directory for 'cd -'
cd() {
  if [[ "$*" == '-' ]]; then
    builtin cd - > /dev/null
  else
    builtin cd "$@"
  fi
}

# make bg and fg accept a bare number instead of %num
bg() {
  if [[ -n "$1" ]]; then
    builtin bg "%$1"
  else
    builtin bg
  fi
}
fg() {
  if [[ -n "$1" ]]; then
    builtin fg "%$1"
  else
    builtin fg
  fi
}

# glob expansion for commands
#
# takes the place of the missing functionality from tcsh's ^Xg
#
# on Cygwin:
# -looks for both pattern and pattern.exe
# -removes *.dll from the results
#
# note: uses $OS_UNAME and requires in_path(), find, sed, and sort
#
gc() {
  # note: bash seems to be inconsistent about whether local declarations 
  # with no initializer create unset or null variables
  local cygflag  # starts out unset/null, not 0
  local path="$PATH"
  local IFS
  local i
  local d
  local f
  local list

  # it's important for $list to start out unset;
  # because we declared it local above, it will still be local
  # when we actually use it
  unset list

  if [[ -z "$1" ]]; then
    echo "Usage: gc 'pattern'"
    return
  fi

  # before we start doing anything messy or time consuming...
  if ! in_path find sed sort; then
    echo "Error: gc requires find, sed, and sort available in the path."
    return
  fi

  [[ "$OS_UNAME" == CYGWIN* ]] && cygflag=1

  # trailing : in $PATH is interpreted as .
  # make it :: so the loop will see it
  # (leading : will already show up)
  [[ "$path" == *: ]] && path="$path:"

  i=0
  IFS=':'
  for d in $path; do  # no quotes
    [[ -z "$d" ]] && d='.'  # :: or leading : in $path

    # have to reset IFS around this command so ${} results will be split 
    # into multiple words
    #
    # have to separate the ^$d and ^/ patterns because dirs with (single) 
    # trailing slashes in $path will only get one slash in the output
    #
    # could use ${//} instead of sed but this is more portable
    # (and probably not much slower overall given the heavy use of find)
    #
    # use : as delimiter in sed because it's guaranteed not to be in $d
    # (or else $d would have been split)
    #
    IFS=' '
    f="$(find -H "$d" -maxdepth 1 -mindepth 1 \
          \( -name "$1" ${cygflag:+-o -name "$1.exe"} \) 2>/dev/null | \
          sed -e "s:^$d::" -e 's:^/::' ${cygflag:+-e '/\.dll$/d'})"
    IFS=':'
    [[ -n "$f" ]] && list["$i"]="$f"

    : $(( i++ ))
  done

  # any member of $list that was actually set won't be null,
  # so there won't be blank lines from (e.g.) directories with no results;
  # but the join will produce "" if there were no results at all, so:
  if [[ -n "${list[*]}" ]]; then
    IFS=$'\n'
    echo "${list[*]}" | sort -u
  fi
}


# --- machine-specific settings, overrides, aliases, etc. ---

[[ -e ~/.bashrc.local ]] && . ~/.bashrc.local
