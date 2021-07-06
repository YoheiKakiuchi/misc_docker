#!/bin/bash

OPT=${DOCKER_OPTION} ## -it --cpuset-cpus 0-2
cname=${DOCKER_CONTAINER:-"cont_vscode_gas"} ## name of container (should be same as in run.sh)

VAR=${@:-"bash"}
if [ $# -eq 0 -a -z "$OPT" ]; then
    OPT=-it
fi

DOCKER_ENVIRONMENT_VAR=""

docker exec ${OPT}          \
       --privileged         \
       ${DOCKER_ENVIRONMENT_VAR} \
       --env="DISPLAY"      \
       --env="QT_X11_NO_MITSHM=1" \
       --workdir="/userdir" \
       ${cname} ${VAR}
