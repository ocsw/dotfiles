#!/usr/bin/env bash

ln_tbu () {
    local source_path="$1"

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
        cat <<EOF
Usage: ln_tbu SOURCE_PATH

ERROR: No source path given.
EOF
        return 1
    fi
    if ! [ -e "$source_path" ]; then
        echo "ERROR: Source path doesn't exist."
        return 1
    fi
    if [ -e "${TBU_DIR}/${source_path##*/}" ]; then
        echo "ERROR: Source already exists in backup directory."
        echo "    Backup directory: $TBU_DIR"
        return 1
    fi

    if ! mv "$source_path" "$TBU_DIR"; then
        echo
        echo "ERROR: Can't move source to backup directory.  Stopping."
        echo "    Backup directory: $TBU_DIR"
        echo
        return 1
    fi
    ln -s "${TBU_DIR}/${source_path##*/}" "$source_path"
}
