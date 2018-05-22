#!/usr/bin/env bash

ln_tbu () {
    local source_path="$1"
    local check_path
    if [ -z "$TBU_DIR" ]; then
        export TBU_DIR="${HOME}/.to_back_up"
    fi
    if ! [ -d "$TBU_DIR" ]; then
        mkdir -p "$TBU_DIR"
    fi
    if [ -z "$source_path" ]; then
        cat <<EOF
Usage: ln_tbu SOURCE_PATH

If SOURCE_PATH is relative, it is interpreted relative to \$TBU_DIR
($TBU_DIR).

ERROR: No source path given.
EOF
        return 1
    fi
    if [[ "$source_path" =~ ^/ ]]; then
        check_path="$source_path"
    else
        check_path="${TBU_DIR}/${source_path}"
    fi
    if ! [ -e "$check_path" ]; then
        echo "ERROR: Source path doesn't exist."
        return 1
    fi
    if [ -e "${TBU}/${source_path##*/}" ]; then
        echo "ERROR: Source already exists in \$TBU_DIR ($TBU_DIR)."
        return 1
    fi
    mv "$source_path" "$TBU_DIR"
    ln -s "${TBU_DIR}/${source_path}" .
}
