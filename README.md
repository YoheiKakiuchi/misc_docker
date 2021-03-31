# build

./wrap_for_docker_xserver.sh --user-directory /path_to_dir --default-command 'sleep 1000' --nvidia your_image_name

image for xserver: your_image_name_xserver
docker-compose -f docker-compose.yaml -p project_name up

build for xserver with nvidia: your_image_name_xserver_nvidia
DISPLAY=:0 xhost +si:localuser:root
docker-compose -f docker-compose.nvidia.yaml -p project_name up

# description

## docker compose

use newer version of docker-compose

'''
$ sudo apt-get remove docker-compose
$ COMPOSE_VERSION=$(wget https://api.github.com/repos/docker/compose/releases/latest -O - | grep 'tag_name' | cut -d\" -f4)
$ sudo wget https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose
$ sudo chmod 755 /usr/local/bin/docker-compose
'''

## using docker xserver

https://github.com/devrt/docker-xserver

## Build ( step by step )

docker build -f Dockerfile.wrap_for_docker_xserver --build-arg BASE_IMAGE=your_build_image -t your_build_image_xserver .

## Build ( step by step for nvidia )

wget https://github.com/hsr-project/tmc_wrs_binary/raw/master/Dockerfile.nvidia

docker build -f Dockerfile.nvidia --build-arg BASE_IMAGE=your_build_image -t your_build_image_nvidia .

## Run with nvidia

DISPLAY=:0 xhost +si:localuser:root
docker-compose -f docker-compose.nvidia.yaml up

