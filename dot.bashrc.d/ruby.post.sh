#!/usr/bin/env bash

# see common.sh
gem () {
    umask_wrap 022 gem "$@"
}
