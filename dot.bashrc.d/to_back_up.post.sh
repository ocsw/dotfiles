#!/usr/bin/env bash

_ln_tbu_usage () {
    cat <<EOF
Usage: ln_tbu SOURCE_PATH

All components of the source path will be recreated under the backup
directory.  Use either paths relative to PWD (no . or ..) or absolute
paths.
EOF
}

ln_tbu () {
    local source_path="$1"
    local source_path_prefix
    local subtree

    if [ -z "$TBU_DIR" ]; then
        export TBU_DIR="${HOME}/.to_back_up"
    fi
    if ! [ -d "$TBU_DIR" ]; then
        if ! mkdir -p "$TBU_DIR"; then
            echo
            echo "ERROR: Can't create backup directory.  Stopping."
            echo "    Backup directory: $TBU_DIR"
            echo
            return 1
        fi
    fi

    if [ -z "$source_path" ]; then
        _ln_tbu_usage
        echo
        echo "ERROR: No source path given."
        return 1
    fi
    if [[ $source_path =~ ^\./ ]] || [[ $source_path =~ ^\.\./ ]]; then
        _ln_tbu_usage
        echo
        echo "ERROR: Source path starts with './' or '../'."
        return 1
    fi
    if ! [ -e "$source_path" ]; then
        echo "ERROR: Source path doesn't exist."
        return 1
    fi
    if [[ $source_path =~ /$ ]]; then
        source_path="${source_path_prefix%%/}"
    fi

    source_path_prefix=""
    subtree=""
    if [[ $source_path =~ / ]]; then
        source_path_prefix="${source_path%/*}"
        subtree="${source_path_prefix##/}/"
    fi
    if [ -n "$source_path_prefix" ]; then
        if ! mkdir -p "${TBU_DIR}/${source_path_prefix##/}"; then
            echo
            echo "ERROR: Can't create source path in backup directory."
            echo "    Backup directory: $TBU_DIR"
            echo
            return 1
        fi
    fi
    if [ -e "${TBU_DIR}/${source_path##/}" ]; then
        echo "ERROR: Source already exists in backup directory."
        echo "    Backup directory: $TBU_DIR"
        return 1
    fi

    if ! mv "$source_path" "${TBU_DIR}/${subtree}"; then
        echo
        echo "ERROR: Can't move source to backup directory.  Stopping."
        echo "    Backup directory: $TBU_DIR"
        echo
        return 1
    fi
    ln -s "${TBU_DIR}/${source_path##/}" "$source_path"
}
