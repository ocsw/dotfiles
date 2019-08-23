#!/usr/bin/env bash

if in_path gcloud; then
    export CLOUDSDK_PYTHON=python3

    gcloud-up () {
        gcloud components update
    }
fi
