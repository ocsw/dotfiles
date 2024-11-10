#!/usr/bin/env bash

# See also ../dot.bash_profile.d/kubernetes.post.sh

if is_available kubectl; then
    if kubectl krew version > /dev/null 2>&1; then
        # See also all-up in updates.post.sh
        krew-up () {
            # Includes update
            kubectl krew upgrade
        }
    fi

    # Docker image for use with e.g. kubectl debug
    # See https://github.com/nicolaka/netshoot
    # shellcheck disable=SC2034
    KUBE_DEBUG_IMAGE="nicolaka/netshoot"
fi
