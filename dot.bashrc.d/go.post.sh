#!/usr/bin/env bash

# VSCode workspace settings for Go repos; run from the root of the repo
# (see vscode.post.sh)
vscode-golang-settings () {
    # this removes highlighting of tabs (there doesn't seem to be a way to do it
    # only for .go files)
    vscode-setting -j "highlight-bad-chars.additionalUnicodeChars" '[""]'
}
