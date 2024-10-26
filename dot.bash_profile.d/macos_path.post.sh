#!/usr/bin/env bash

if [ "$(uname)" = "Darwin" ] && [ -d /usr/local/sbin ] &&
        ! is_path_component "/usr/local/sbin" ; then
    export PATH="${PATH//\/usr\/sbin://usr/local/sbin:/usr/sbin:}"
fi
