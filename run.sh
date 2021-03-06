#!/bin/bash

OPT=${DOCKER_OPTION} ## -it --cpuset-cpus 0-2
iname=${DOCKER_IMAGE:-"ubuntu:18.04"} ##
cname=${DOCKER_CONTAINER:-"misc_docker"} ## name of container (should be same as in exec.sh)

DEFAULT_USER_DIR="$(pwd)"
mtdir=${MOUNTED_DIR:-$DEFAULT_USER_DIR}

VAR=${@:-"bash"}
if [ $# -eq 0 -a -z "$OPT" ]; then
    OPT=-it
fi

## --net=mynetworkname
## docker inspect -f '{{.NetworkSettings.Networks.mynetworkname.IPAddress}}' container_name
## docker inspect -f '{{.NetworkSettings.Networks.mynetworkname.Gateway}}'   container_name

NET_OPT="--net=host"
# for gdb
#NET_OPT="--net=host --env=DOCKER_ROS_IP --env=DOCKER_ROS_MASTER_URI --cap-add=SYS_PTRACE --security-opt=seccomp=unconfined"

##xhost +local:root
xhost +si:localuser:root

docker rm ${cname}

docker run ${OPT}    \
    --privileged     \
    --gpus 'all,"capabilities=compute,graphics,utility,display"' \
    ${NET_OPT}       \
    --env="DISPLAY"  \
    --env="QT_X11_NO_MITSHM=1" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --name=${cname} \
    --volume="${mtdir}:/userdir" \
    -w="/userdir" \
    ${iname} ${VAR}

##xhost -local:root

## capabilities
# compute	CUDA / OpenCL アプリケーション
# compat32	32 ビットアプリケーション
# graphics	OpenGL / Vulkan アプリケーション
# utility	nvidia-smi コマンドおよび NVML
# video		Video Codec SDK
# display	X11 ディスプレイに出力
# all
