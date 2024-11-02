#!/usr/bin/env bash

# See also ../dot.bashrc.d/kubernetes.post.sh

# Can't use is_available() for gcloud because we define a function with the
# same name later and we might be re-sourcing this
if is_available kubectl && in_path gcloud; then
    export USE_GKE_GCLOUD_AUTH_PLUGIN=True
fi

if kubectl krew version > /dev/null 2>&1; then
    if ! is_path_component "${HOME}/.krew/bin" &&
            [ -d "${HOME}/.krew/bin" ]; then
        export PATH="${PATH}:${HOME}/.krew/bin"
    fi
fi
