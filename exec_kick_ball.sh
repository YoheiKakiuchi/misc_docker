#!/bin/bash

iname=${DOCKER_IMAGE:-"irslrepo/humanoid_sim:melodic"} ##
cname=${DOCKER_CONTAINER:-"docker_humanoid_sim"} ## name of container (should be same as in exec.sh)

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

docker exec ${cname} /irsl_entrypoint.sh vglrun roseus /catkin_ws/src/rtmros_choreonoid/hrpsys_choreonoid_tutorials/euslisp/action_and_perception/kick-ball-demo.l '(kick-ball-to-goal-demo)' &

CHILD_PID="$!"

wait ${CHILD_PID}

exit 0
