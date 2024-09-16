#!/usr/bin/env bash

_vscode-golang-settings-usage () {
    cat 1>&2 <<EOF
Usage:
    vscode-golang-settings [ -f|--file PATH_TO_SETTINGS_FILE ] [ -t TAGS ]

Adds Go settings to a VSCode project.

Must be run from the root of the VSCode project directory unless a path is given with -f / --file.  That option is particularly useful for workspace files.
EOF
}

# (see vscode.post.sh)
vscode-golang-settings () {
    local vsc_settings_file=".vscode/settings.json"
    local tags=""
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -f|--file)
                vsc_settings_file="$2"
                shift
                shift
                ;;
            -t|--tags)
                tags="$2"
                shift
                shift
                ;;
            -h|--help)
                _vscode-setting-usage
                return 0
                ;;
            *)
                _vscode-setting-usage
                return 1
                ;;
        esac
    done

    # this removes highlighting of tabs (there doesn't seem to be a way to do it
    # only for .go files)
    vscode-setting -f "$vsc_settings_file" -j \
        "highlight-bad-chars.additionalUnicodeChars" '[""]'

    if [ -n "$tags" ]; then
        vscode-setting -f "$vsc_settings_file" -j \
            "go.buildFlags" "[\"-tags=${tags}\"]"
        vscode-setting -f "$vsc_settings_file" -j \
            "go.toolsEnvVars" "{\"GOTAGS\": \"${tags}\"}"
        vscode-setting -f "$vsc_settings_file" -j \
            "go.lintFlags" "[
                \"-E\", \"exportloopref,goimports,lll,revive,whitespace\",
                \"-E\", \"stylecheck\",
                \"--max-issues-per-linter\", \"0\",
                \"--max-same-issues\", \"0\",
                \"--fast\",
                \"--build-tags\", \"${tags}\"
            ]"
    fi
}
