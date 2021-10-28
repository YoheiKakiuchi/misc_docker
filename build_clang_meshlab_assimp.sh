#!/bin/bash

set -e

docker build . -f Dockerfile.clang   --build-arg BASE_IMAGE=nvidia/opengl:1.2-glvnd-runtime-ubuntu20.04 --pull -t yoheikakiuchi/clang:20.04
docker build . -f Dockerfile.meshlab --build-arg BASE_IMAGE=yoheikakiuchi/clang:20.04 --build-arg TAG_FOR_BUILD=Meshlab-2021.07 \
       -t tmp_build
docker build . -f Dockerfile.assimp  --build-arg BASE_IMAGE=tmp_build --build-arg TAG_FOR_BUILD=v5.0.1 \
       -t yoheikakiuchi/meshlab_and_assimp:20.04
