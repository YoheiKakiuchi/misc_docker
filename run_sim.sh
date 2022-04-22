#!/bin/bash

iname=${DOCKER_IMAGE:-"irslrepo/humanoid_sim:melodic"} ##
cname=${DOCKER_CONTAINER:-"docker_humanoid_sim"} ## name of container (should be same as in exec.sh)

###
CHILD_PID=""

sig_hdl () {
    echo "catch signal $1"

    if [ -n "$CHILD_PID" ]; then
        kill -$1 $CHILD_PID
    fi

    exit 0
}

trap "sig_hdl SIGTERM" SIGTERM
trap "sig_hdl SIGINT" SIGINT
trap "sig_hdl SIGHUP" SIGHUP
###

DEFAULT_USER_DIR="$(pwd)"
mtdir=${MOUNTED_DIR:-$DEFAULT_USER_DIR}


VAR=${@:-"bash"}
if [ $# -eq 0 -a -z "$OPT" ]; then
    OPT=-it
fi

if [ "$NO_GPU" = "" ]; then
    GPU_OPT='--gpus all,"capabilities=compute,graphics,utility,display"'
else
    GPU_OPT=""
fi

## --net=mynetworkname
## docker inspect -f '{{.NetworkSettings.Networks.mynetworkname.IPAddress}}' container_name
## docker inspect -f '{{.NetworkSettings.Networks.mynetworkname.Gateway}}'   container_name

NET_OPT="--net=host"
# for gdb
#NET_OPT="--net=host --env=DOCKER_ROS_IP --env=DOCKER_ROS_MASTER_URI --cap-add=SYS_PTRACE --security-opt=seccomp=unconfined"

DOCKER_ENVIRONMENT_VAR=""

##xhost +local:root
xhost +si:localuser:root

docker rm ${cname}

docker run \
    --privileged     \
    ${GPU_OPT}       \
    ${NET_OPT}       \
    ${DOCKER_ENVIRONMENT_VAR} \
    --env="DOCKER_ROS_SETUP=/catkin_ws/devel/setup.bash" \
    --env="ROS_IP=localhost" \
    --env="ROS_MASTER_URI=http://localhost:11311" \
    --env="DISPLAY=:1"  \
    --env="VGL_DISPLAY=:0" \
    --env="QT_X11_NO_MITSHM=1" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --name=${cname} \
    --volume="${mtdir}:/userdir" \
    -w="/userdir" \
    ${iname} \
    /irsl_entrypoint.sh vglrun rtmlaunch hrpsys_choreonoid_tutorials jaxon_jvrc_choreonoid.launch LOAD_OBJECTS:=true &

CHILD_PID="$!"

wait ${CHILD_PID}

exit 0

##xhost -local:root

## capabilities
# compute	CUDA / OpenCL アプリケーション
# compat32	32 ビットアプリケーション
# graphics	OpenGL / Vulkan アプリケーション
# utility	nvidia-smi コマンドおよび NVML
# video		Video Codec SDK
# display	X11 ディスプレイに出力
# all
