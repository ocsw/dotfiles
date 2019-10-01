#!/usr/bin/env bash

if in_path docker; then
    docker-ls-all() {
        docker image ls --all
        docker container ls --all
        docker volume ls
    }
fi
