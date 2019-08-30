#!/usr/bin/env bash

if in_path go; then
    gopath_tmp="${GOPATH:-$(go env GOPATH)}"
    # don't check for the directory's existence so that we don't need to
    # restart after both installing Go and the creation of the directory
    if [ -n "$gopath_tmp" ] && ! is_path_component "${gopath_tmp}/bin"; then
        export PATH="${PATH}:${gopath_tmp}/bin"
    fi
    unset gopath_tmp
fi
