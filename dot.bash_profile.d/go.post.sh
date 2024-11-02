#!/usr/bin/env bash

# See also ../dot.bashrc.d/go.post.sh

if is_available go; then
    gopath_tmp="${GOPATH:-$(go env GOPATH)}"
    if [ -n "$gopath_tmp" ] && ! is_path_component "${gopath_tmp}/bin" && \
            [ -d "${gopath_tmp}/bin" ]; then
        export PATH="${PATH}:${gopath_tmp}/bin"
    fi
    unset gopath_tmp
fi
