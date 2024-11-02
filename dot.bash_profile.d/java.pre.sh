#!/usr/bin/env bash

# See also ../dot.bashrc.d/java.post.sh

if is_available jenv; then
    if ! is_path_component "${HOME}/.jenv/bin" &&
            [ -d "${HOME}/.jenv/bin" ]; then
        export PATH="${HOME}/.jenv/bin:${PATH}"
    fi
    if ! is_path_component "${HOME}/.jenv/shims" &&
            [ -d "${HOME}/.jenv/shims" ]; then
        export PATH="${HOME}/.jenv/shims:${PATH}"
    fi
fi
