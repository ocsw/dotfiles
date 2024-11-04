#!/usr/bin/env bash

# See also ../dot.bashrc.d/scm_prompt.post.sh

# See https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
export GIT_PS1_STATESEPARATOR=" "
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
# verbose = with counts, auto = without
export GIT_PS1_SHOWUPSTREAM=auto
