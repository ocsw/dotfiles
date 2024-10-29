#!/usr/bin/env bash

# See also vscode-setting.post.sh, which was pulled out for ease of external
# reference, and vscode-go.post.sh

vscode-check-config () {
    # See system_setup.post.sh
    if [ -z "$SYSTEM_SETUP" ]; then
        echo "ERROR: SYSTEM_SETUP must contain the path to the 'system-setup' repo." \
            1>&2
        return 1
    fi

    # See https://github.com/ocsw/system-setup/blob/main/vscode/extensions.txt
    diff "${SYSTEM_SETUP}/vscode/extensions.txt" \
        <(jq -r '.[].identifier.id' < \
            "${HOME}/.vscode/extensions/extensions.json" | sort -t. -k2 -u)

    # See https://github.com/ocsw/system-setup/blob/main/vscode/settings.json
    # and https://github.com/ocsw/system-setup/blob/main/vscode/keybindings.json
    if [ "$(uname)" = "Darwin" ]; then
        local user_config_dir="${HOME}/Library/Application Support/Code/User"
        diff "${SYSTEM_SETUP}/vscode/settings.json" \
            "${user_config_dir}/settings.json"
        diff "${SYSTEM_SETUP}/vscode/keybindings.json" \
            "${user_config_dir}/keybindings.json"
    fi
}
