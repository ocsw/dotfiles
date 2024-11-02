#!/usr/bin/env bash

# See also ../dot.bashrc.d/brew.post.sh

# Paths on Apple Silicon
if [ "$(uname)" = "Darwin" ] && [ -d "/opt/homebrew" ]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"
    if ! is_path_component "${HOMEBREW_PREFIX}/bin"; then
        export PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"
    fi
    if ! [[ $MANPATH =~ (^|:)${HOMEBREW_PREFIX}/share/man(:|$) ]]; then
        # need the trailing : if there is no MANPATH
        export MANPATH="${HOMEBREW_PREFIX}/share/man:${MANPATH}"
    fi
    if ! [[ $INFOPATH =~ (^|:)${HOMEBREW_PREFIX}/share/info(:|$) ]]; then
        export INFOPATH="${HOMEBREW_PREFIX}/share/info:${INFOPATH}"
    fi
fi
