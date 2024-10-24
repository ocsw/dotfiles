#!/usr/bin/env bash

# See also vscode-setting.post.sh, which was pulled out for ease of external
# reference, and vscode-go.post.sh

vscode-check-config () {
    # check global first
    local setup_repo="${SYSTEM_SETUP:-${HOME}/repos/system-setup}"

    # See https://github.com/ocsw/system-setup/blob/main/vscode/extensions.txt
    diff "${setup_repo}/vscode/extensions.txt" \
        <(jq -r '.[].identifier.id' < \
            "${HOME}/.vscode/extensions/extensions.json" | sort -t. -k2 -u)

    # See https://github.com/ocsw/system-setup/blob/main/vscode/settings.json
    # and https://github.com/ocsw/system-setup/blob/main/vscode/keybindings.json
    if [ "$(uname)" = "Darwin" ]; then
        local user_config_dir="${HOME}/Library/Application Support/Code/User"
        diff "${setup_repo}/vscode/settings.json" \
            "${user_config_dir}/settings.json"
        diff "${setup_repo}/vscode/keybindings.json" \
            "${user_config_dir}/keybindings.json"
    fi
}
