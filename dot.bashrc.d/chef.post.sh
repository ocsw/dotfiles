#!/usr/bin/env bash

# See also ../dot.bash_profile.d/chef.pre.sh

if is_available chef; then
    eval "$(chef shell-init "$(basename "$SHELL")" | grep -v '^export ')"
fi
