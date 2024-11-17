#!/usr/bin/env bash

# See also ../dot.bashrc.d/iterm2.post.sh

# See https://iterm2.com/documentation-utilities.html (which is incomplete) and
# https://github.com/gnachman/iTerm2-shell-integration/tree/main/utilities
# (There's a more complete list/description at the bottom of
# https://github.com/gnachman/iTerm2-shell-integration/blob/main/shell_integration/install_shell_integration_and_utilities.sh
# but it's also not fully complete)
ITERM2_UTILITIES_DIR="/Applications/iTerm.app/Contents/Resources/utilities"

if [ "$TERM_PROGRAM" = iTerm.app ]; then
    # iTerm2 now does this when starting a shell, but just in case...
    if ! is_path_component "$ITERM2_UTILITIES_DIR" &&
            [ -d "$ITERM2_UTILITIES_DIR" ]; then
        export PATH="${PATH}:${ITERM2_UTILITIES_DIR}"
    fi
fi
