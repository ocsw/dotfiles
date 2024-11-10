#!/usr/bin/env bash

# See common.sh
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

# Can't use is_available() because we defined a function with the same name
if in_path gcloud; then
    # See also all-up in updates.post.sh
    gcloud-up () {
        gcloud components update
    }
fi
