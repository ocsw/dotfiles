#!/usr/bin/env bash

TBU_DIR="${HOME}/.to_back_up"

_ln_tbu_usage () {
    cat <<EOF
Usage: ln_tbu SOURCE_PATH

Moves the file/directory/etc. at the SOURCE_PATH to the backup directory set in
\$TBU_DIR and replaces it with a symlink to the new location.  The idea is to
put things like config files in a single place that can be easily added to
backup or sync software.

Within the backup directory, the source will be placed within a subtree of
directories matching the source's path, with one exception: if the orignal path
starts with the value of \$HOME, it will be stripped first.

For example, ~/.config/app/config.json will me moved to
\$TBU_DIR/.config/app/.config.json.

This makes it easier to work with the files in the backup directory, but it
does mean that this function will group together items from \$HOME and / with
the same first path component, and it will fail if they have the same
destinations.  However, that's unlikely to come up in practice.

SOURCE_PATH may not contain any .. elements.

TBU_DIR must be an absolute path, and it will be created if it doesn't
exist.

This function will refuse to move the source if the destination already exists,
so it's safe to run it multiple times with the same source.
EOF
}

ln_tbu () {
    local source="$1"
    local source_clean
    local source_stripped
    local subtree
    local source_name
    local destination

    if [ -z "$TBU_DIR" ]; then
        echo "ERROR: \$TBU_DIR must contain the path to the backup directory." \
            1>&2
        return 1
    fi

    if ! [[ $TBU_DIR =~ ^/ ]]; then
        echo "ERROR: \$TBU_DIR must be an absolute path." 1>&2
        return 1
    fi

    if ! [ -d "$TBU_DIR" ]; then
        if ! mkdir -p "$TBU_DIR"; then
            echo 1>&2
            printf "%s\n" \
                "ERROR: Can't create backup directory '$TBU_DIR'" 1>&2
            echo 1>&2
            return 1
        fi
    fi

    if [ -z "$source" ]; then
        _ln_tbu_usage 1>&2
        echo 1>&2
        echo "ERROR: No source given." 1>&2
        return 1
    fi

    # I'm not going to mess with resolving '..', so just break
    if [[ $source =~ ^\.\./ ]] || [[ $source =~ /\.\.$ ]] ||
        [[ $source =~ /\.\./ ]]; then
        _ln_tbu_usage 1>&2
        echo 1>&2
        echo "ERROR: Source path contains .." 1>&2
        return 1
    fi

    if ! [ -e "$source" ]; then
        echo "ERROR: Source doesn't exist." 1>&2
        return 1
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
        sed -e 's|^\./||' -e 's|/\.$||' -e 's|/\./|/|g' -e 's|///*|/|g')

    # Make relative paths absolute
    if ! [[ $source_clean =~ ^/ ]]; then
        source_clean="${PWD}/${source_clean}"
    fi

    # Figure out the subtree under $TBU_DIR; first, remove $HOME as a prefix,
    # then leading and trailing slashes
    source_stripped="${source_clean#"$HOME"}"
    source_stripped="${source_stripped#/}"
    source_stripped="${source_stripped%/}"

    # Now we need to split what's left into a subtree and a name
    if ! [[ $source_stripped =~ / ]]; then
        subtree=""
        source_name="$source_stripped"
    else
        subtree="${source_stripped%/*}/"
        source_name="${source_stripped##*/}"
    fi

    if [ -n "$subtree" ]; then
        if ! mkdir -p "${TBU_DIR}/${subtree%/}"; then
            echo 1>&2
            printf "%s\n" \
                "ERROR: Can't create subtree '$subtree' in backup directory '$TBU_DIR'." \
                1>&2
            echo 1>&2
            return 1
        fi
    fi

    destination="${TBU_DIR}/${subtree}${source_name}"

    if [ -e "$destination" ]; then
        printf "%s\n" "ERROR: Destination '$destination' already exists." 1>&2
        return 1
    fi

    if ! mv "$source" "$destination"; then
        echo 1>&2
        printf "%s\n" \
            "ERROR: Can't move source to backup destination '$destination'." \
            1>&2
        echo 1>&2
        return 1
    fi
    ln -s "$destination" "$source"
}
