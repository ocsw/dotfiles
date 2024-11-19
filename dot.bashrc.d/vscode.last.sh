#!/usr/bin/env bash

# See also vscode.pre.sh and vscode.post.sh

if [ "$TERM_PROGRAM" = "vscode" ]; then
    # See https://code.visualstudio.com/docs/terminal/shell-integration
    #
    # Hardcoding is faster than 'code --locate-shell-integration-path bash' and
    # doesn't require that code is already in the PATH
    VSCODE_BASH_INTEGRATION_PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
    #
    # VSCODE_SHELL_INTEGRATION is set by the integration script
    # shellcheck disable=SC1090
    if [ -z "$VSCODE_SHELL_INTEGRATION" ] &&
            [ -e "$VSCODE_BASH_INTEGRATION_PATH" ]; then
        . "$VSCODE_BASH_INTEGRATION_PATH"
    fi
fi
