#!/usr/bin/env bash

if is_available jenv; then
    eval "$(jenv init - | grep -v 'export PATH=')"
fi
