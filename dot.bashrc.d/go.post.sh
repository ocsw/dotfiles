#!/usr/bin/env bash

# See also ../dot.bash_profile.d/go.post.sh and vscode-go.post.sh

#
# Notes about GOPRIVATE components:
#
# They must include all private orgs/repos from which you will be downloading
# Go modules (e.g. with 'go get' or 'go mod download')
#
# They will typically look like 'github.com/ORG_NAME' or
# 'github.com/ORG_NAME/REPO_NAME'
#
# They use path.Match glob syntax, and are prefixes; see
# https://pkg.go.dev/path#Match
#
# They don't need trailing slashes or /*.  Trailing slashes are ignored, and
# matches are against entire slash-separated path sections, meaning that /org
# won't match /organization.  (/org* will, but don't do that unless you
# specifically want that behavior.)
#
# You may need to add the "org" of an individual account (or accounts)
#
# Over-scoping them (e.g. including an org that has both public and private
# repos) is probably harmless; the consequences for the public repos are:
#
#   * Increased traffic to the public repo (no caching by proxy.golang.org)
#   * Increased privacy, arguably (no paths being sent to proxy.golang.org)
#   * No verification against sum.golang.org (but hashes are calculated and
#     stored for subsequent verification)
#
# See https://go.dev/ref/mod#private-modules for more details about what
# GOPRIVATE actually does
#
# Anything included in GOPRIVATE probably needs a corresponding insteadOf for
# HTTPS in your Git config; see
# https://github.com/ocsw/system-setup/blob/main/unix-common/git.psh
#
# For reference: It took a bunch of spelunking through the Go source code, but
# I found that the matching is implemented in MatchPrefixPatterns, here:
# https://cs.opensource.google/go/x/mod/+/refs/tags/v0.21.0:module/module.go;l=802
# (I don't know why something this central is in a /x repo, but anyway...)
#

#
# Handle private repos in Go (add to GOPRIVATE)
#
# URLs can be passed in a single argument, or multiple.  They use path.Match
# glob syntax, and are prefixes.  See the notes above for more details.
goprivate-add () {
    # shellcheck disable=SC2048
    for i in $*; do  # no quotes; URLs can't contain spaces anyway
        if ! [[ $GOPRIVATE =~ (^|,)${i}(,|$) ]]; then
            GOPRIVATE+=",${i}"
        fi
    done
    GOPRIVATE="${GOPRIVATE#,}"
    export GOPRIVATE
}
