#!/usr/bin/env bash

# See also ../dot.bash_profile.d/hstr.post.sh

if is_available hstr; then
    # See https://github.com/dvorka/hstr/blob/master/CONFIGURATION.md

    [[ $- =~ .*i.* ]] && bind '"\C-r": "\C-ahstr -- \C-j"'

    alias hh="hstr"
    alias hhn="hstr -n"
fi
