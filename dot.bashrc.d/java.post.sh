#!/usr/bin/env bash

# See also ../dot.bash_profile.d/java.pre.sh

if is_available jenv; then
    eval "$(jenv init - | grep -v 'export PATH=')"
fi
