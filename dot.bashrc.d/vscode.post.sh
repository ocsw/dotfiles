#!/usr/bin/env bash

# (see also go.post.sh)

_vscode-setting-usage () {
    cat 1>&2 <<EOF
Usage:
    vscode-setting -s|--set|--set-string SETTING_NAME SETTING_VALUE
    vscode-setting -j|--set-json SETTING_NAME SETTING_JSON
    vscode-setting -u|--unset SETTING_NAME
    vscode-setting -g|--get SETTING_NAME

Sets, unsets, or gets a VSCode workspace setting using jq.

Must be run from the root of the VSCode workspace directory.
EOF
}

vscode-setting () {
    local argc
    local mode
    local jq_arg
    local setting_name
    local setting_value
    local vsc_dir=".vscode"
    local vsc_settings_file="${vsc_dir}/settings.json"
    local cur_setting
    local new_file_contents

    argc="$#"
    mode=""
    jq_arg=""
    setting_name=""
    setting_value=""
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -s|--set|--set-string)
                mode="set"
                jq_arg="--arg"
                setting_name="$2"
                setting_value="$3"
                shift
                shift
                shift
                ;;
            -j|--set-json)
                mode="set"
                jq_arg="--argjson"
                setting_name="$2"
                setting_value="$3"
                shift
                shift
                shift
                ;;
            -u|--unset)
                mode="unset"
                setting_name="$2"
                shift
                shift
                ;;
            -g|--get)
                mode="get"
                setting_name="$2"
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

    if [ -z "$setting_name" ]; then
        _vscode-setting-usage
        echo 1>&2
        echo "ERROR: No setting name supplied." 1>&2
        return 1
    fi
    # check for unsupplied value; explicit empty string is ok
    if [ "$mode" = "set" ] && [ "$argc" -ne 3 ]; then
        _vscode-setting-usage
        echo 1>&2
        echo "ERROR: No setting value supplied (use \"\" for empty strings)." \
            1>&2
        return 1
    fi

    if ! hash jq > /dev/null 2>&1; then
        echo "ERROR: The jq utility isn't available." 1>&2
        return 1
    fi

    if [ "$mode" = "get" ]; then
        if ! [ -f "$vsc_settings_file" ]; then
            return 0
        fi
        if ! cur_setting=$(jq ".\"${setting_name}\"" < "$vsc_settings_file" \
                2>/dev/null); then
            echo "ERROR: Can't process VSCode settings file."
            return 1
        fi
        # remove JSON quotes
        cur_setting="${cur_setting#\"}"
        cur_setting="${cur_setting%\"}"
        if [ -z "$cur_setting" ] || [ "$cur_setting" = "null" ]; then
            return 0
        fi
        printf "%s\n" "$cur_setting"
    elif [ "$mode" = "unset" ]; then
        if ! [ -f "$vsc_settings_file" ]; then
            return 0
        fi
        if ! new_file_contents=$(jq --indent 4 "del(.\"${setting_name}\")" \
                < "$vsc_settings_file"); then
            echo "ERROR: Can't process VSCode settings file."
            return 1
        fi
        # this isn't ideal, but it's portable, unlike something like mktemp,
        # and it should be fine in this context; Bash variables can contain
        # many megabytes, and the command-line-length limit doesn't apply to
        # builtins like printf
        # see:
        # https://stackoverflow.com/questions/5076283/shell-variable-capacity
        # https://stackoverflow.com/questions/19354870/bash-command-line-and-input-limit
        printf "%s\n" "$new_file_contents" >| "$vsc_settings_file"
    elif [ "$mode" = "set" ]; then
        mkdir -p "$vsc_dir"
        # the jq addition won't work on a blank file
        if ! [ -f "$vsc_settings_file" ] || \
                ! grep '{' "$vsc_settings_file" > /dev/null 2>&1; then
            echo "{}" >| "$vsc_settings_file"
        fi
        if ! new_file_contents=$(jq --indent 4 \
                "$jq_arg" new_val "$setting_value" \
                ". + {\"${setting_name}\": \$new_val}" \
                < "$vsc_settings_file"); then
            echo "ERROR: Can't process VSCode settings file."
            return 1
        fi
        # see note above, in the unset section
        printf "%s\n" "$new_file_contents" >| "$vsc_settings_file"
    fi
}
