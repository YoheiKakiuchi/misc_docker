#!/bin/bash

iname=${DOCKER_IMAGE:-"novnc"} ##
cname=${DOCKER_CONTAINER:-"browser_novnc"} ## name of container (should be same as in exec.sh)

xhost +si:localuser:root

docker rm ${cname}

docker run \
    --privileged \
    --gpus 'all,"capabilities=compute,graphics,utility,display"' \
    --net=host \
    --env="NOVNC_WEB_PORT=6080" \
    --env="DISPLAY=:1" \
    --env="VGL_DISPLAY=:0" \
    --env="QT_X11_NO_MITSHM=1" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --name=${cname} \
    ${iname}

##xhost -local:root

## capabilities
# compute	CUDA / OpenCL アプリケーション
# compat32	32 ビットアプリケーション
# graphics	OpenGL / Vulkan アプリケーション
# utility	nvidia-smi コマンドおよび NVML
# video		Video Codec SDK
# display	X11 ディスプレイに出力
# all
