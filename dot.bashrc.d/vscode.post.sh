#!/usr/bin/env bash

# See also vscode-setting.post.sh, which was pulled out for ease of external
# reference

vscode-check-config () {
    diff "${SYSTEM_SETUP}/vscode/extensions.txt" \
        <(jq -r '.[].identifier.id' < \
            "${HOME}/.vscode/extensions/extensions.json" | sort -t. -k2 -u)

    if [ "$(uname)" = "Darwin" ]; then
        local USER_CONFIG_DIR="${HOME}/Library/Application Support/Code/User"
        diff "${SYSTEM_SETUP}/vscode/settings.json" \
            "${USER_CONFIG_DIR}/settings.json"
        diff "${SYSTEM_SETUP}/vscode/keybindings.json" \
            "${USER_CONFIG_DIR}/keybindings.json"
    fi
}
