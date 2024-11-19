#!/usr/bin/env bash

# See also ../dot.bash_profile.d/iterm2.post.sh

if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
    # See https://iterm2.com/documentation-shell-integration.html
    #
    # Source is in
    # https://github.com/gnachman/iTerm2-shell-integration/tree/main/shell_integration
    ITERM2_BASH_INTEGRATION_PATH="/Applications/iTerm.app/Contents/Resources/iterm2_shell_integration.bash"
    #
    # ITERM_SHELL_INTEGRATION_INSTALLED is set by the integration script, at
    # least as of v18
    # shellcheck disable=SC1090
    if [ -z "$ITERM_SHELL_INTEGRATION_INSTALLED" ] &&
            [ -e "$ITERM2_BASH_INTEGRATION_PATH" ]; then
        . "$ITERM2_BASH_INTEGRATION_PATH"
    fi
fi
