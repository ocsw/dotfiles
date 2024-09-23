#!/usr/bin/env bash

_vscode-golang-settings-usage () {
    cat 1>&2 <<EOF
Usage:
    vscode-golang-settings [-t|--tags TAGS] [OPTIONS]

Adds Go settings to a VSCode workspace.  To include build tags, use -t or
--tags.

If the settings file does not exist, it will be created (as will the path to
it).

The command must be run from the root of the VSCode project directory.
Alternatively, specify '-f|--file PATH_TO_SETTINGS_FILE'; this is particularly
useful for multi-folder workspace files.  Additionally, for multi-folder
workspace files use '-w|--workspace', which puts the settings under the
'settings' section of the file (rather than at the top level, as in regular
config files).

The file will be formatted with 4-space indents; to change this, specify
'-i|--indent NUM'.

Options can appear in any order.  Later options override earlier ones.
EOF
}

# (see vscode-setting.post.sh)
vscode-golang-settings () {
    local tags=""
    local vsc_settings_file=".vscode/settings.json"
    local workspace_arg=""
    local indent=4

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -t|--tags)
                tags="$2"
                shift
                shift
                ;;
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

_vscode-golang-settings-complete () {
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    local prev_word=""

    if [ "$COMP_CWORD" -ge 1 ]; then
        prev_word="${COMP_WORDS[$COMP_CWORD-1]}"
    fi

    COMPREPLY=()

    case "$prev_word" in
        -t|--tags)
            return 0
            ;;
        -f|--file)
            while read -r line; do
                COMPREPLY+=("$line")
            done < <(compgen -o default "$cur_word")
            return 0
            ;;
        -i|--indent)
            # jq only allows 0-7
            COMPREPLY=(0 1 2 3 4 5 6 7)
            return 0
            ;;
    esac

    while read -r line; do
        COMPREPLY+=("$line")
    done < <(compgen -W "
            -t --tags -f --file -w --workspace -i --indent -h --help
        " -- "$cur_word")
}
complete -F _vscode-golang-settings-complete vscode-golang-settings
