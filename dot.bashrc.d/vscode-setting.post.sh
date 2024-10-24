#!/usr/bin/env bash

# (See also vscode-go.post.sh)

_vscode-setting-usage () {
    cat 1>&2 <<EOF
Usage:
    vscode-setting -s|--set|--set-string SETTING_NAME SETTING_VALUE [OPTIONS]
    vscode-setting -j|--set-json SETTING_NAME SETTING_JSON [OPTIONS]
    vscode-setting -u|--unset SETTING_NAME [OPTIONS]
    vscode-setting -g|--get SETTING_NAME [OPTIONS]

Sets, unsets, or gets a VSCode workspace setting.

If the settings file does not exist, it will be created (as will the path to
it).

The command must be run from the root of the VSCode project directory.
Alternatively, specify '-f|--file PATH_TO_SETTINGS_FILE'; this is particularly
useful for multi-folder workspace files.  Additionally, for multi-folder
workspace files use '-w|--workspace', which puts the settings under the
'settings' section of the file (rather than at the top level, as in regular
config files).

The file will be formatted with 4-space indents when setting or unsetting a
value; to change this, specify '-i|--indent NUM'.  This also applies when
getting JSON-valued settings.

When overwriting an existing setting, a warning will be printed to stderr with
the setting's previous value.  This can be suppressed with -q|--quiet.

Options can appear in any order.  Later options override earlier ones.
EOF
}

# uses jq
vscode-setting () {
    local mode
    local jq_arg
    local setting_name
    local setting_value
    local missing_value
    local vsc_settings_file=".vscode/settings.json"
    local workspace_mode
    local indent
    local quiet
    local settings_root
    local setting_path
    local cur_setting
    local present
    local new_file_contents
    local null_arg
    local source

    mode=""
    jq_arg=""
    setting_name=""
    setting_value=""
    missing_value="no"
    workspace_mode="no"
    indent=4
    quiet="no"
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -s|--set|--set-string)
                mode="set"
                jq_arg="--arg"
                setting_name="$2"
                setting_value="$3"
                # allow for explicit "" but not a lack of argument
                if [ "$#" -lt 3 ]; then
                    missing_value=yes
                fi
                shift
                shift
                shift
                ;;
            -j|--set-json)
                mode="set"
                jq_arg="--argjson"
                setting_name="$2"
                setting_value="$3"
                # allow for explicit "" but not a lack of argument
                if [ "$#" -lt 3 ]; then
                    missing_value=yes
                fi
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
            -f|--file)
                vsc_settings_file="$2"
                shift
                shift
                ;;
            -w|--workspace)
                workspace_mode="yes"
                shift
                ;;
            -i|--indent)
                indent="$2"
                shift
                shift
                ;;
            -q|--quiet)
                quiet="yes"
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

    if [ -z "$mode" ]; then
        _vscode-setting-usage
        echo 1>&2
        echo "ERROR: No action (set/unset/get) specified." 1>&2
        return 1
    fi

    if [ -z "$setting_name" ]; then
        _vscode-setting-usage
        echo 1>&2
        echo "ERROR: No setting name specified." 1>&2
        return 1
    fi
    # check for unspecified value; explicit empty string is ok
    if [ "$mode" = "set" ] && [ "$missing_value" = "yes" ]; then
        _vscode-setting-usage
        echo 1>&2
        echo "ERROR: No setting value specified (use \"\" for empty strings)." \
            1>&2
        return 1
    fi

    if ! jq --version > /dev/null 2>&1; then  # maximally portable test
        echo "ERROR: The jq utility isn't available." 1>&2
        return 1
    fi

    settings_root="."
    if [ "$workspace_mode" = "yes" ]; then
        settings_root=".settings"
    fi
    setting_path=".\"${setting_name}\""
    if [ "$workspace_mode" = "yes" ]; then
        setting_path=".settings.\"${setting_name}\""
    fi

    if [ "$mode" = "get" ] || [ "$mode" = "unset" ]; then
        if ! [ -e "$vsc_settings_file" ]; then
            echo "ERROR: VSCode settings file not found." 1>&2
            return 1
        fi
        if ! present=$(jq "$settings_root | has(\"${setting_name}\")" \
                < "$vsc_settings_file"); then
            echo "ERROR: Can't process VSCode settings file." 1>&2
            return 1
        fi
        if [ "$present" != "true" ]; then
            echo "ERROR: Setting not present in VSCode settings file." 1>&2
            return 1
        fi
    fi

    if [ "$mode" = "get" ]; then
        if ! cur_setting=$(jq -r --indent "$indent" "$setting_path" \
                < "$vsc_settings_file"); then
            echo "ERROR: Can't process VSCode settings file." 1>&2
            return 1
        fi
        if [ -z "$cur_setting" ] || [ "$cur_setting" = '""' ] || \
                [ "$cur_setting" = "null" ]; then  # JSON null
            return 0
        fi
        printf "%s\n" "$cur_setting"
    elif [ "$mode" = "unset" ]; then
        if ! new_file_contents=$(jq --indent "$indent" "del($setting_path)" \
                < "$vsc_settings_file"); then
            echo "ERROR: Can't process VSCode settings file." 1>&2
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
        mkdir -p "$(dirname "$vsc_settings_file")"
        # the jq addition won't work on a blank file
        null_arg=""
        source="$vsc_settings_file"
        if ! [ -s "$vsc_settings_file" ]; then
            null_arg="--null-input"
            source="/dev/null"
        fi

        # warn on overwrite
        if [ "$quiet" != "yes" ]; then
            if ! present=$(jq "$settings_root | has(\"${setting_name}\")" \
                    < "$source"); then
                echo "ERROR: Can't process VSCode settings file." 1>&2
                return 1
            fi
            if [ "$present" == "true" ]; then
                if ! cur_setting=$(jq -r --indent "$indent" "$setting_path" \
                        < "$source"); then
                    echo "ERROR: Can't process VSCode settings file." 1>&2
                    return 1
                fi
                printf "%s\n" "Warning: overwriting previous setting for $setting_path, which was:" 1>&2
                printf "%s\n" "$cur_setting" 1>&2
            fi
        fi

        # shellcheck disable=SC2086
        if ! new_file_contents=$(jq $null_arg --indent "$indent" \
                "$jq_arg" new_val "$setting_value" \
                "$settings_root += {\"${setting_name}\": \$new_val}" \
                < "$source"); then
            echo "ERROR: Can't process VSCode settings file." 1>&2
            return 1
        fi
        # see note above, in the unset section
        printf "%s\n" "$new_file_contents" >| "$vsc_settings_file"
    fi
}

_vscode-setting-complete () {
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    local prev_word=""
    local prevprev_word=""

    if [ "$COMP_CWORD" -ge 1 ]; then
        prev_word="${COMP_WORDS[$COMP_CWORD-1]}"
    fi
    if [ "$COMP_CWORD" -ge 2 ]; then
        prevprev_word="${COMP_WORDS[$COMP_CWORD-2]}"
    fi

    COMPREPLY=()

    case "$prevprev_word" in
        -s|--set|--set-string|-j|--set-json)
            return 0
            ;;
    esac

    case "$prev_word" in
        -s|--set|--set-string|-j|--set-json|-u|--unset|-g|--get)
            return 0
            ;;
        -f|--file)
            while IFS= read -r comp; do
                COMPREPLY+=("$comp")
            done < <(compgen -o default -- "$cur_word")
            return 0
            ;;
        -i|--indent)
            # jq only allows 0-7
            COMPREPLY=(0 1 2 3 4 5 6 7)
            return 0
            ;;
    esac

    while IFS= read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "
            -s --set --set-string -j --set-json -u --unset -g --get -f --file
            -w --workspace -i --indent -q --quiet -h --help
        " -- "$cur_word")
}
complete -F _vscode-setting-complete vscode-setting
