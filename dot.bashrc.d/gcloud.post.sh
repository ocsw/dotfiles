#!/usr/bin/env bash

if is_available gcloud; then
    export CLOUDSDK_PYTHON=python3

    gcloud-up () {
        gcloud components update
    }
fi
