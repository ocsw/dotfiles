#!/usr/bin/env bash

# This repo; see https://github.com/ocsw/dotfiles
DOTFILE_REPO="${HOME}/repos/dotfiles"

_add_dotfile () {
    local operation="$1"
    local dotfile="$2"
    local target_dir="$3"
    local cmd

    if [ -z "$DOTFILE_REPO" ]; then
        echo "ERROR: DOTFILE_REPO must contain the path to the 'dotfiles' repo."
        return 1
    fi

    if ! [ -d "$DOTFILE_REPO" ]; then
        echo "ERROR: Dotfile repo missing."
        return 1
    fi
    if [ -z "$operation" ]; then
        echo "ERROR: No operation given."
        return 1
    fi
    if [ -z "$dotfile" ]; then
        printf "%s\n" "Usage: ${operation}_dotfile DOTFILE TARGET_DIR"
        echo "Specify DOTFILE without the 'dot' prefix, e.g. '.bashrc'."
        echo "If TARGET_DIR isn't given, it defaults to \$HOME."
        echo
        echo "ERROR: No dotfile given."
        return 1
    fi
    if ! [ -e "${DOTFILE_REPO}/dot${dotfile}" ]; then
        echo "ERROR: No such dotfile in the repo."
        return 1
    fi
    if [ -z "$target_dir" ]; then
        target_dir="$HOME"
    fi
    if [ -e "${target_dir}/${dotfile}" ]; then
        echo "ERROR: Target already exists."
        return 1
    fi
    case "$operation" in
        ln)
            cmd="ln -s"
            ;;
        cp)
            cmd="cp"
            ;;
        *)
            echo "ERROR: Unknown operation."
            return 1
            ;;
    esac

    $cmd "${DOTFILE_REPO}/dot${dotfile}" "${target_dir}/${dotfile}"
}

ln_dotfile () {
    _add_dotfile "ln" "$@"
}

cp_dotfile () {
    _add_dotfile "cp" "$@"
}
