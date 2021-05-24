#!/bin/bash
docker build . -f Dockerfile.clang   --build-arg BASE_IMAGE=nvidia/opengl:1.2-glvnd-runtime-ubuntu20.04 -t yoheikakiuchi/clang:20.04
docker build . -f Dockerfile.meshlab --build-arg BASE_IMAGE=yoheikakiuchi/clang:20.04                   -t tmp_build
docker build . -f Dockerfile.assimp  --build-arg BASE_IMAGE=tmp_build                                   -t yoheikakiuchi/meshlab_and_assimp:20.04
