#!/bin/bash

OPT=$1
while [ ! "$OPT" = "" ];
do
    # echo "OPT: $OPT"
    case $OPT in
        --xserver-image)
            XS_IMAGE=$2
            shift
            ;;
        --port)
            XS_PORT=$2
            shift
            ;;
        --image)
            MAIN_IMAGE=$2
            shift
            ;;
        --command)
            COMMAND=$2
            shift
            ;;
        --env)
            ENV_VAR=$2
            shift
            ;;
        --user-directory)
            USER_DIR=$2
            shift
            ;;
        --docker-directory)
            DOCKER_DIR=$2
            shift
            ;;
        --help)
            echo "$0 [option] image_name"
            echo "option: --xserver-image arg"
            echo "option: --port arg"
            echo "option: --image arg"
            echo "option: --command arg"
            echo "option: --env arg"
            echo "option: --user-directory arg"
            echo "option: --docker-directory arg"
            exit 0
            ;;
        *)
            if [ ! "$OPT" = "" ]; then
                in_image=$OPT
            fi
            ;;
    esac
    shift
    OPT=$1
done

## xserver_image | devrt/xserver
if [ ! "${XS_IMAGE}" = "" ]; then
    sed -i -e "s@devrt/xserver@${XS_IMAGE}@g" ${in_image}
fi
## port | 3000:80
if [ ! "${XS_PORT}" = "" ]; then
    sed -i -e "s@3000:80@${XS_PORT}:80@g" ${in_image}
fi
## simulator-image | ___image_name___
if [ ! "${MAIN_IMAGE}" = "" ]; then
    sed -i -e "s@___image_name___@${MAIN_IMAGE}@g" ${in_image}
fi
## command | #command:___command___
if [ ! "${COMMAND}" = "" ]; then
    sed -i -e "s@#command:___command___@command: ${COMMAND}@g" ${in_image}
fi
## environment-variables | ######- ___extra-environment-variables___
### KEY=VAL;KEY=VAL;KEY=VAL -> - KEY=VAL\n - KEY=VAL\n.
if [ ! "${ENV_VAR}" = "" ]; then
    set -f
    P_IFS=${IFS}
    IFS=";"

    set -- ${ENV_VAR}

    IFS=${P_IFS}
    set +f

    if [ "$#" -gt 0 ]; then
        OFFSET="      - "
        TEMP="# added by scripts\n"
        for cnt in $(seq "$#") ; do
            TEMP="${TEMP}${OFFSET}$1\n"
            shift
        done
        TEMP="${TEMP}# (end added)"
        ## echo "HOGE" | sed -e "s/HOGE/${TEMP}/"
        sed -i -e "s@######- ___extra-environment-variables___@${TEMP}@g" ${in_image}
    fi
fi
## docker_dir | /userdir
if [ ! "${USER_DIR}" = "" ]; then
    sed -i -e "s@/userdir@${USER_DIR}@g" ${in_image}
fi
## host_dir | ___user_directory___
if [ ! "${DOCKER_DIR}" = "" ]; then
    sed -i -e "s@___user_directory___@${DOCKER_DIR}@g" ${in_image}
fi

# (test)
# configure_compose.sh  --xserver-image xxximage --port 9999 --image yyyimage --command '[bash, -c, q]' --env "KEY1=VAL1;KEY2=VAL2;KEY3=VAL3" --user-directory '/test_user_dir' --docker-directory '/test_docker_dir' docker-compose.yaml
#
