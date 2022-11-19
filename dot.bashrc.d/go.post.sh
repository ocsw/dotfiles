#!/usr/bin/env bash

# VSCode workspace settings for Go repos; run from the root of the repo
# (see vscode.post.sh)
vscode-golang-settings () {
    # this removes highlighting of tabs (there doesn't seem to be a way to do it
    # only for .go files)
    vscode-setting -j "highlight-bad-chars.additionalUnicodeChars" '[""]'

    local tags="$1"
    if [ -n "$tags" ]; then
        vscode-setting -j "go.buildFlags" "[\"-tags=${tags}\"]"
        vscode-setting -j "go.toolsEnvVars" "{\"GOTAGS\": \"${tags}\"}"
        vscode-setting -j "go.lintFlags" "[
            \"-E\", \"exportloopref,goimports,lll,revive,whitespace\",
            \"-E\", \"stylecheck\",
            \"--max-issues-per-linter\", \"0\", \"--max-same-issues\", \"0\",
            \"--fast\",
            \"--build-tags\", \"${tags}\"
        ]"
    fi
}
