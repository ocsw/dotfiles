#!/usr/bin/env bash

TBU_DIR="${TBU_DIR:-${HOME}/.to_back_up}"
TBUV_DIR="${TBUV_DIR:-${HOME}/.to_back_up_volatile}"

_ln_tbu_usage () {
    cat <<EOF
Usage: ln_tbu SOURCE_PATH [BACKUP_DIR]

Moves the file/directory/etc. at the SOURCE_PATH to the backup directory
BACKUP_DIR and replaces it with a symlink to the new location.  The idea is to
put things like config files in a single place that can be easily added to
backup or sync software.

Within the backup directory, the source will be placed within a subtree of
directories matching the source's path, with one exception: if the orignal path
starts with the value of \$HOME, it will be stripped first.

For example, ~/.config/app/config.json will me moved to
BACKUP_DIR/.config/app/.config.json.

This makes it easier to work with the files in the backup directory, but it
does mean that this function will group together items from \$HOME and / with
the same first path component, and it will fail if they have the same
destinations.  However, that's unlikely to come up in practice.

SOURCE_PATH may not contain any .. elements and must already exist.

BACKUP_DIR must be an absolute path, and it will be created if it doesn't
exist.  It defaults to the value of \$TBU_DIR.

This function will refuse to move the source if the destination already exists,
so it's safe to run it multiple times with the same source.
EOF
}

ln_tbuv () {
    ln_tbu "$1" "$TBUV_DIR"
}

ln_tbu () {
    local source="$1"
    local backup_dir="$2"
    local err
    local source_clean
    local source_stripped
    local subtree
    local source_name
    local destination

    if [ "$source" = "-h" ] || [ "$source" = "--help" ] ; then
        _ln_tbu_usage
        return
    fi

    if [ -z "$source" ]; then
        _ln_tbu_usage 1>&2
        echo 1>&2
        echo "ERROR: No source given." 1>&2
        return 1
    fi

    # I'm not going to mess with resolving '..', so just break
    if [[ $source =~ ^\.\./ ]] || [[ $source =~ /\.\.$ ]] ||
        [[ $source =~ /\.\./ ]] || [ "$source" = ".." ]; then
        echo 1>&2
        echo "ERROR: Source path contains a '..' element." 1>&2
        echo 1>&2
        return 1
    fi

    if ! [ -e "$source" ]; then
        echo 1>&2
        echo "ERROR: Source doesn't exist." 1>&2
        echo 1>&2
        return 1
    fi

    if [ -z "$backup_dir" ]; then
        #echo "No BACKUP_DIR given; defaulting to \$TBU_DIR ('$TBU_DIR')."

        if [ -z "$TBU_DIR" ]; then
            echo 1>&2
            echo "ERROR: \$TBU_DIR is unset or empty." 1>&2
            echo 1>&2
            return 1
        fi

        backup_dir="$TBU_DIR"
    fi

    if ! [[ $backup_dir =~ ^/ ]]; then
        echo 1>&2
        echo "ERROR: BACKUP_DIR must be an absolute path." 1>&2
        echo 1>&2
        return 1
    fi

    if ! [ -d "$backup_dir" ]; then
        printf "%s\n" "Creating backup directory..."
        if ! err=$(mkdir -p "$backup_dir" 2>&1); then
            echo 1>&2
            printf "%s\n" "ERROR: $err" 1>&2
            echo 1>&2
            return 1
        fi
    fi

    #
    # Clean up the source path
    #
    # We could use realpath here, which would also have handled .., but we
    # don't want to resolve symlinks, necessarily, just make sure we have
    # something usable.
    #
    # Strip out '.' elements from the path and condense multiple slashes
    source_clean=$(printf "%s\n" "$source" |
        sed -e 's|^\./||' -e 's|/\.$|/|' -e 's|/\./|/|g' -e 's|^\.$||' \
            -e 's|///*|/|g')

    # Make relative paths absolute
    if ! [[ $source_clean =~ ^/ ]]; then
        source_clean="${PWD}/${source_clean}"
    fi

    # Remove the trailing slash, if present.  Note that if this is left in
    # place, ln will later fail because it will think we want it to make the
    # symlink inside the source directory, which will already have been moved.
    source_clean="${source_clean%/}"

    # If there's nothing left, we were being asked to operate on /
    # (Wait until this point to check so that we've already cleaned up, e.g.,
    # '/.')
    if [ -z "$source_clean" ]; then
        echo 1>&2
        echo "ERROR: Source cannot be '/'." 1>&2
        echo 1>&2
        return 1
    fi

    # Figure out the subtree under $backup_dir; first, remove $HOME as a
    # prefix
    # (See https://www.shellcheck.net/wiki/SC2295 about the quotes)
    source_stripped="${source_clean#"$HOME"}"

    # If there's nothing left, we were being asked to operate on $HOME
    # (Wait until this point to check so that we've already cleaned up, e.g.,
    # '~/.')
    # (That's actually fine; the mv will fail later if the BACKUP_DIR is inside
    # $HOME, but otherwise, we can just treat it like a regular absolute path)
    if [ -z "$source_stripped" ]; then
        source_stripped="$HOME"
    fi

    # Strip the leading slash if there is one
    source_stripped="${source_stripped#/}"

    # Now we need to split what's left into a subtree and a name
    if ! [[ $source_stripped =~ / ]]; then
        subtree=""
        source_name="$source_stripped"
    else
        subtree="${source_stripped%/*}/"
        source_name="${source_stripped##*/}"
    fi

    if [ -n "$subtree" ] && ! [ -d "${backup_dir}/${subtree%/}" ]; then
        printf "%s\n" "Creating subtree '$subtree' under backup directory..."
        if ! err=$(mkdir -p "${backup_dir}/${subtree%/}" 2>&1); then
            echo 1>&2
            printf "%s\n" "ERROR: $err" 1>&2
            echo 1>&2
            return 1
        fi
    fi

    destination="${backup_dir}/${subtree}${source_name}"
    printf "%s\n" "Source: $source_clean"
    printf "%s\n" "Destination: $destination"

    if [ -e "$destination" ]; then
        echo 1>&2
        printf "%s\n" "ERROR: Destination already exists." 1>&2
        echo 1>&2
        return 1
    fi

    printf "%s\n" "Moving source to destination..."
    if ! err=$(mv "$source_clean" "$destination" 2>&1); then
        echo 1>&2
        printf "%s\n" "ERROR: $err" 1>&2
        echo 1>&2
        return 1
    fi

    printf "%s\n" "Linking source to destination..."
    if ! err=$(ln -s "$destination" "$source_clean" 2>&1); then
        echo 1>&2
        printf "%s\n" "ERROR: $err" 1>&2
        echo 1>&2
        return 1
    fi

    echo "Done."
}
