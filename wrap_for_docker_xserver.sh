#!/bin/bash

## repo/name:tag -> repo/name:tag_xserver -> repo/name:tag_xserver_nvidia

OPT=$1
while [ ! "$OPT" = "" ];
do
    # echo "OPT: $OPT"
    case $OPT in
        --default-command)
            DEFUALT_COMMAND=$2
            shift
            ;;
        --user-directory)
            USER_DIR=$2
            shift
            ;;
        --output-directory)
            OUTPUT_DIR=$2
            shift
            ;;
        --nvidia)
            USE_NVIDIA=true
            ;;
        --ros)
            USE_ROS=true
            ;;
        --supervisor)
            USE_SUPERVISOR=true
            ;;
        --help)
            echo "$0 [option] image_name"
            echo "option: --nvidia"
            echo "option: --ros"
            echo "option: --supervisor"
            echo "option: --default-command arg"
            echo "option: --user-directory arg"
            echo "option: --output-directory arg"
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

if [ "${in_image}" = "" ]; then
    echo "IMAGE_NAME should be set!"
    exit 1
fi

if [ "${USER_DIR}" = "" ]; then
    USER_DIR=$(pwd)
fi

if [ "${OUTPUT_DIR}" = "" ]; then
    OUTPUT_DIR='./'
fi

if [ "${DEFAULT_COMMAND}" = "" ]; then
    DEFAULT_COMMAND="bash -c 'while true; do sleep 5; done'";
fi

echo "in_image: ${in_image}"
echo "USER_DIR: ${USER_DIR}"
# echo "OUTPUT_DIR: ${OUTPUT_DIR}"
echo "DEFAULT_COMMAND: ${DEFAULT_COMMAND}"

## docker-compose.yaml, docker-compose.nvidia.yaml
cp configs/docker-compose.yaml .
sed -i -e "s@___image_name___@${in_image}_xserver@g" docker-compose.yaml
sed -i -e "s@___user_directory___@${USER_DIR}@g"     docker-compose.yaml

### BUILD
docker build --no-cache -f Dockerfile.wrap_for_docker_xserver --build-arg BASE_IMAGE=${in_image} -t ${in_image}_xserver .

if [ "${USE_SUPERVISOR}" = "true" ]; then
    ## supervisord.conf
    cp configs/supervisord.conf .
    sed -i -e "s@___default_command___@${DEFAULT_COMMAND}@g" supervisord.conf
    docker build --no-cache -f Dockerfile.wrap_for_docker_xserver.supervisor --build-arg BASE_IMAGE=${in_image}_xserver -t ${in_image}_xserver .
else
    echo "Warning!"
    echo "Warning!"
    echo "Warning! You should add default-command to docker-compose.yaml!"
    echo "Warning!"
    echo "Warning!"
fi

if [ "${USE_ROS}" = "true" ]; then
    ## my_entry ...
    (cd scripts; ./download_entry.sh)
    docker build --no-cache -f Dockerfile.wrap_for_docker_xserver.ros --build-arg BASE_IMAGE=${in_image}_xserver -t ${in_image}_xserver .
fi

## for NVIDIA
if [ ! "${USE_NVIDIA}" = "" ]; then
    if [ ! -e Dockerfile.nvidia ]; then
        wget https://github.com/hsr-project/tmc_wrs_binary/raw/master/Dockerfile.nvidia -O Dockerfile.nvidia
    fi

    if [ ! $(grep -c vglrun Dockerfile.nvidia) -eq 0 ]; then
        sed -i -e '$d' Dockerfile.nvidia
    fi

    cp configs/docker-compose.nvidia.yaml .
    sed -i -e "s@___image_name___@${in_image}_xserver_nvidia@g" docker-compose.nvidia.yaml
    sed -i -e "s@___user_directory___@${USER_DIR}@g"            docker-compose.nvidia.yaml

    ### BUILD
    docker build --no-cache -f Dockerfile.nvidia --build-arg BASE_IMAGE=${in_image}_xserver -t ${in_image}_xserver_nvidia .
fi
