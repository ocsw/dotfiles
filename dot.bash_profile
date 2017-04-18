# --- overrides to /etc/profile ---

export PAGER='less -E'


# --- additions ---

# see also $DIRPAGER and more and lessx aliases in .bashrc
# note: use of '?a .' gets around %t being broken
export LESS='-QX -Ps?m(%i/%m).?f?a .%f.?e?a .(END):?pB?a .%pB\%..?c?a .[Col %c].?e?x - Next\: %x.%t$'
export LESSHISTFILE=/dev/null

export MANPAGER='less -F'
# note: \% and \: from original prompt don't need extra \ in bash
export MANOPT='-r ?m(%i/%m).?a\ .Manual\ page\ \$MAN_PN?e?a\ .(END):?pB?a\ .%pB\%..?c?a\ .[Col\ %c].?e?x\ -\ Next\:\ %x.%t'


# --- source .bashrc ---
[[ -e ~/.bashrc ]] && . ~/.bashrc
