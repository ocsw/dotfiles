#!/usr/bin/env bash

# see common.sh
gcloud () {
    local arg
    for arg in "$@"; do
        if [ "$arg" = "components" ]; then
            umask_wrap 022 gcloud "$@"
            return "$?"
        fi
    done
    command gcloud "$@"
}

# can't use is_available() because we defined a function with the same name
if in_path gcloud; then
    gcloud-up () {
        gcloud components update
    }
fi
