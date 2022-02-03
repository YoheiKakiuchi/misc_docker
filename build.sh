#!/bin/bash

docker build -f Dockerfile.add_ros -t add_ros .
docker build --no-cache -f Dockerfile.novnc --build-arg BASE_IMAGE=add_ros -t novnc .
