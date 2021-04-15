#!/bin/bash

OPT=${DOCKER_OPTION} ## -it --cpuset-cpus 0-2
cname=${DOCKER_CONTAINER:-"___proc_name___"} ## name of container (should be same as in run.sh)

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
       --workdir="___user_dir___" \
       ${cname} ${VAR}

## ___proc_name___
## VAR=${@:-"bash"}
## DOCKER_ENVIRONMENT_VAR=""
## ___user_dir___
