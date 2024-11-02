#!/usr/bin/env bash

# Used in PS1 in ../dot.bashrc
_errorcode_prompt () {
    # first copy the status array in case we do something that changes it as we
    # go along
    local pipestatus_num=("${PIPESTATUS[@]}")

    local stat_num signame pipestatus_sig
    # local (at least on bash 3) sets pipstatus_sig[0] (to null), so we need to
    # unset it; the local attribute will remain
    unset pipestatus_sig

    for stat_num in "${pipestatus_num[@]}"; do
        if [ "$stat_num" -gt 128 ]; then
            signame=$(builtin kill -l $((stat_num - 128)) 2>/dev/null)
            # different versions of Bash are inconsistent about the SIG prefix
            signame="${signame#SIG}"
            pipestatus_sig=("${pipestatus_sig[@]}" "$stat_num ($signame)")
        else
            # this would be better but less backwards-compatible:
            # pipestatus_sig+=("$stat_num")
            # see https://stackoverflow.com/questions/1951506/add-a-new-element-to-an-array-without-specifying-the-index-in-bash
            pipestatus_sig=("${pipestatus_sig[@]}" "$stat_num")
        fi
    done

    printf "%s" "${pipestatus_sig[*]}"
}
