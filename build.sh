#!/bin/bash

_ROS_DIST=noetic

docker build -f Dockerfile.add_ros.${_ROS_DIST} -t add_ros:${_ROS_DIST} .
docker build --no-cache -f Dockerfile.novnc --build-arg BASE_IMAGE=add_ros:${_ROS_DIST} -t novnc:${_ROS_DIST} .
