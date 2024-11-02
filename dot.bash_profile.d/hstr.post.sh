#!/usr/bin/env bash

# See also ../dot.bashrc.d/hstr.post.sh

if is_available hstr; then
    HSTR_CONFIG="hicolor"
    HSTR_CONFIG="${HSTR_CONFIG},prompt-bottom"
    HSTR_CONFIG="${HSTR_CONFIG},raw-history-view"
    HSTR_CONFIG="${HSTR_CONFIG},duplicates"
    HSTR_CONFIG="${HSTR_CONFIG},verbose-kill"
    HSTR_CONFIG="${HSTR_CONFIG},blacklist"
    HSTR_CONFIG="${HSTR_CONFIG},warning"
    export HSTR_CONFIG

    export HSTR_PROMPT="hstr> "
fi
