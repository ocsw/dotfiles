#!/usr/bin/env bash

# See also vscode-setting.post.sh, which was pulled out for ease of external
# reference, and vscode-go.post.sh

vscode-check-config () {
    # check global first
    local setup_repo="${SYSTEM_SETUP:-${HOME}/repos/system-setup}"

    diff "${setup_repo}/vscode/extensions.txt" \
        <(jq -r '.[].identifier.id' < \
            "${HOME}/.vscode/extensions/extensions.json" | sort -t. -k2 -u)

    if [ "$(uname)" = "Darwin" ]; then
        local user_config_dir="${HOME}/Library/Application Support/Code/User"
        diff "${setup_repo}/vscode/settings.json" \
            "${user_config_dir}/settings.json"
        diff "${setup_repo}/vscode/keybindings.json" \
            "${user_config_dir}/keybindings.json"
    fi
}
