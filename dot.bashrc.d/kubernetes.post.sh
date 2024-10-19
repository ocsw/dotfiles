#!/usr/bin/env bash

if is_available kubectl; then
    # can't use is_available() for gcloud because we defined a function with
    # the same name
    if in_path gcloud; then
        export USE_GKE_GCLOUD_AUTH_PLUGIN=True
    fi

    # Docker image for use with e.g. kubectl debug
    # shellcheck disable=SC2034
    KUBE_DEBUG_IMAGE="nicolaka/netshoot"
fi
