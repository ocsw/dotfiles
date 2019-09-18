#!/usr/bin/env bash

# see common.sh
gcloud () {
    local env_var="CLOUDSDK_PYTHON=python3"
    local arg
    if ! python3 --version > /dev/null 2>&1; then
        env_var="CLOUDSDK_PYTHON=python"
    fi
    for arg in "$@"; do
        if [ "$arg" = "components" ]; then
            umask_wrap 022 env "$env_var" gcloud "$@"
            return "$?"
        fi
    done
    # env also acts like the 'command' builtin - it bypasses aliases and
    # functions
    env "$env_var" gcloud "$@"
}

# can't use is_available() because we just defined a function with the same name
if in_path gcloud; then
    export CLOUDSDK_PYTHON=python3

    gcloud-up () {
        gcloud components update
    }
fi
