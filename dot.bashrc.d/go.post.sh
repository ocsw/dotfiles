#!/usr/bin/env bash

_vscode-golang-settings-usage () {
    cat 1>&2 <<EOF
Usage:
    vscode-golang-settings [ -t|--tags TAGS ] [ OPTIONS ]

Adds Go settings to a VSCode workspace.  To include build tags, use -t or
--tags.

The command must be run from the root of the VSCode project directory.
Alternatively, specify '-f|--file PATH_TO_SETTINGS_FILE'; this is particularly
useful for multi-folder workspace files.  Additionally, for multi-folder
workspace files use '-w|--workspace', which puts the settings under the
'settings' section of the file (rather than at the top level, as in regular
config files).

The file will be formatted with 4-space indents; to change this, specify
'-i|--indent NUM'.

Options can appear in any order.
EOF
}

# (see vscode-setting.post.sh)
vscode-golang-settings () {
    local vsc_settings_file=".vscode/settings.json"
    local workspace_arg=""
    local indent=4
    local tags=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -f|--file)
                vsc_settings_file="$2"
                shift
                shift
                ;;
            -w|--workspace)
                workspace_arg="-w"
                shift
                ;;
            -i|--indent)
                indent="$2"
                shift
                shift
                ;;
            -t|--tags)
                tags="$2"
                shift
                shift
                ;;
            -h|--help)
                _vscode-golang-settings-usage
                return 0
                ;;
            *)
                _vscode-golang-settings-usage
                return 1
                ;;
        esac
    done

    # this removes highlighting of tabs (there doesn't seem to be a way to do it
    # only for .go files)
    vscode-setting -f "$vsc_settings_file" $workspace_arg -i "$indent" -j \
        "highlight-bad-chars.additionalUnicodeChars" '[""]'

    if [ -n "$tags" ]; then
        vscode-setting -f "$vsc_settings_file" $workspace_arg -i "$indent" -j \
            "go.buildFlags" "[\"-tags=${tags}\"]"
        vscode-setting -f "$vsc_settings_file" $workspace_arg -i "$indent" -j \
            "go.toolsEnvVars" "{\"GOTAGS\": \"${tags}\"}"
        vscode-setting -f "$vsc_settings_file" $workspace_arg -i "$indent" -j \
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
