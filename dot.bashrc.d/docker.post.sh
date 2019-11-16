#!/usr/bin/env bash

if is_available docker; then
    docker-ls-all() {
        docker image ls --all
        docker container ls --all
        docker volume ls
    }
fi
