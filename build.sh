#!/bin/bash

wget -P /tmp https://raw.githubusercontent.com/IRSL-tut/irsl_docker/main/Dockerfile.add_virtualgl
wget -P /tmp https://raw.githubusercontent.com/IRSL-tut/irsl_docker/main/Dockerfile.add_glvnd
wget -P /tmp https://raw.githubusercontent.com/IRSL-tut/irsl_docker/main/Dockerfile.add_entrypoint

PULLORIGIN="--pull"
ORIGIN_IMAGE=ros:melodic-base
CACHED=""
TARGET_NAME=irslrepo/humanoid_sim:melodic

BUILD_A=build_temp/add_glvnd:melodic
BUILD_B=build_temp/add_virtualgl:melodic
BUILD_C=build_temp/humanoid_sim:melodic

echo "## ADD glvnd"
docker build . ${CACHED} ${PULLORIGIN} -f /tmp/Dockerfile.add_glvnd      --build-arg BASE_IMAGE=${ORIGIN_IMAGE} -t ${BUILD_A}
echo "## ADD virtual_gl"
docker build . ${CACHED}               -f /tmp/Dockerfile.add_virtualgl  --build-arg BASE_IMAGE=${BUILD_A} -t ${BUILD_B}
echo "## BUILD main"
docker build . ${CACHED}               -f Dockerfile                     --build-arg BASE_IMAGE=${BUILD_B} -t ${BUILD_C}
echo "## ADD entrypoint"
docker build . ${CACHED}               -f /tmp/Dockerfile.add_entrypoint --build-arg BASE_IMAGE=${BUILD_C} -t ${TARGET_NAME}
