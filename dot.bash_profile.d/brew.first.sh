#!/usr/bin/env bash

# See also ../dot.bashrc.d/brew.post.sh

if [ "$(uname)" = "Darwin" ]; then
    # Don't just use 'brew shellenv' because it's not idempotent (and also
    # doesn't have as many checks, it seems)

    if [ -d "/opt/homebrew" ]; then
        # Apple Silicon
        export HOMEBREW_PREFIX="/opt/homebrew"
        export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
        export HOMEBREW_REPOSITORY="/opt/homebrew"

        if ! is_path_component "${HOMEBREW_PREFIX}/sbin" &&
                [ -d "${HOMEBREW_PREFIX}/sbin" ]; then
            export PATH="${HOMEBREW_PREFIX}/sbin:${PATH}"
        fi
        if ! is_path_component "${HOMEBREW_PREFIX}/bin" &&
                [ -d "${HOMEBREW_PREFIX}/bin" ]; then
            export PATH="${HOMEBREW_PREFIX}/bin:${PATH}"
        fi
    elif [ -d "/usr/local/Cellar" ]; then
        # Intel
        export HOMEBREW_PREFIX="/usr/local"
        export HOMEBREW_CELLAR="/usr/local/Cellar"
        export HOMEBREW_REPOSITORY="/usr/local/Homebrew"

        # /usr/local/bin will already be in the PATH, and macos_path.post.sh
        # will add /usr/local/sbin in the proper place
    fi

    if [ -n "$HOMEBREW_PREFIX" ]; then
        # man can find the Brew manpages based on the PATH, as long as the Brew
        # bin directory is in it; see manpath(1).  We do need to make sure that
        # if there's an explicit MANPATH, it has a leading :, meaning that the
        # default directories are included (and are searched first).
        [ -n "$MANPATH" ] && export MANPATH=":${MANPATH#:}"

        if ! [[ $INFOPATH =~ (^|:)${HOMEBREW_PREFIX}/share/info(:|$) ]] && \
                [ -d "${HOMEBREW_PREFIX}/share/info" ]; then
            # If there is no prior INFOPATH, we still need the trailing :, so
            # that the default directories are searched.  Unlike with man, a
            # leading : does nothing; see
            # https://www.gnu.org/software/texinfo/manual/texinfo/html_node/Other-Info-Directories.html.
            # (info, at least the one from the texinfo package, does seem to be
            # able to do the same PATH-searching trick as man.  But 'brew
            # shellenv' includes this, so...)
            export INFOPATH="${HOMEBREW_PREFIX}/share/info:${INFOPATH}"
        fi
    fi
fi
