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

# If flux was installed outside of Brew, add the bash completions
if is_available flux; then
    # Can't use is_available() because we defined a function with the same name
    if ! in_path brew ||
            ! [ -f "${HOMEBREW_PREFIX}/etc/bash_completion.d/flux" ]; then
        # See https://fluxcd.io/flux/installation/
        # shellcheck disable=SC1090
        . <(flux completion bash)  # why is this not working???
    fi
fi
