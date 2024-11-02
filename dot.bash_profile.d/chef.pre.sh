#!/usr/bin/env bash

# See also ../dot.bashrc.d/chef.post.sh

if is_available chef; then
    if ! [[ $PATH =~ /.chef/ ]]; then
        eval "$(chef shell-init "$(basename "$SHELL")" | grep '^export ')"
    fi
    export CHEF_LICENSE=accept-silent
fi
