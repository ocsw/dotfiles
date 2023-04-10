#!/usr/bin/env bash

# can't use is_available() for gcloud because we defined a function with the
# same name
if in_path gcloud && is_available kubectl; then
    export USE_GKE_GCLOUD_AUTH_PLUGIN=True
fi
