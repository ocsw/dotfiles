#!/usr/bin/env bash

# See also vscode.post.sh and vscode.last.sh

if [ "$TERM_PROGRAM" = "vscode" ]; then
    # shellcheck disable=SC2034
    MARKLVL=$((SHLVL - 1))
fi
