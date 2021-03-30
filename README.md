# build

## using docker xserver

https://github.com/devrt/docker-xserver

## docker compose

'''
$ sudo apt-get remove docker-compose
$ COMPOSE_VERSION=$(wget https://api.github.com/repos/docker/compose/releases/latest -O - | grep 'tag_name' | cut -d\" -f4)
$ sudo wget https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose
$ sudo chmod 755 /usr/local/bin/docker-compose
'''

## Build

wget https://github.com/hsr-project/tmc_wrs_binary/raw/master/Dockerfile.nvidia

docker build -f Dockerfile.nvidia --build-arg BASE_IMAGE=your_build_image -t your_build_image_nvidia .


## Run (normal)

docker-compose -f docker-compose.yaml up


## Run with nvidia

DISPLAY=:0 xhost +si:localuser:root
docker-compose -f docker-compose.nvidia.yaml up