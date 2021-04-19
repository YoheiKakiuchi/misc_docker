ARG BASE_IMAGE
#FROM osrf/ros:melodic-desktop
FROM ${BASE_IMAGE}

ARG ROS_SOURCE

## gazebo versions
# gazebo9_9.0.0
# gazebo9_9.1.0
# gazebo9_9.1.1
# gazebo9_9.2.0
# gazebo9_9.3.0
# gazebo9_9.3.1
# gazebo9_9.4.0
# gazebo9_9.4.1
# gazebo9_9.5.0
# gazebo9_9.6.0
# gazebo9_9.7.0
# gazebo9_9.8.0
# gazebo9_9.9.0
# gazebo9_9.10.0
# gazebo9_9.11.0
# gazebo9_9.12.0
# gazebo9_9.13.0
# gazebo9_9.13.1
# gazebo9_9.14.0
# gazebo9_9.15.0
# gazebo9_9.16.0
# gazebo11_11.0.0
# gazebo11_11.1.0
# gazebo11_11.2.0
# gazebo11_11.3.0
##
#ARG _BUILD_GAZEBO_VERSION=9
#ARG _BUILD_GAZEBO_TAG=gazebo9_9.0.0
#ARG _BUILD_GZ_ROS_PKG_TAG=2.8.7
##
#ARG _BUILD_GAZEBO_VERSION=9
#ARG _BUILD_GAZEBO_TAG=gazebo9_9.16.0
#ARG _BUILD_GZ_ROS_PKG_TAG=2.8.7
##
ARG _BUILD_GAZEBO_VERSION=11
ARG _BUILD_GAZEBO_TAG=gazebo11_11.0.0
ARG _BUILD_GZ_ROS_PKG_TAG=2.8.7

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND noninteractive

MAINTAINER YoheiKakiuchi <youhei@jsk.imi.i.u-tokyo.ac.jp>

RUN apt update -q -qq && \
    apt dist-upgrade -q -qq -y && \
    apt install -q -qq -y ros-${ROS_DISTRO}-perception cmake wget git software-properties-common ros-${ROS_DISTRO}-catkin apt-utils && \
    apt remove -q -qq -y '.*gazebo.*' '.*sdformat.*' '.*ignition-math.*' '.*ignition-msgs.*' '.*ignition-transport.*' && \
    apt autoremove -y && \
    apt clean && rm -rf /var/lib/apt/lists/

## add required deb files for gazebo
RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list
RUN wget https://packages.osrfoundation.org/gazebo.key -O - | apt-key add -
RUN apt update -q -qq && \
    wget https://raw.githubusercontent.com/ignition-tooling/release-tools/master/jenkins-scripts/lib/dependencies_archive.sh -O /tmp/dependencies.sh && \
    GAZEBO_MAJOR_VERSION=${_BUILD_GAZEBO_VERSION} ROS_DISTRO=${ROS_DISTRO} . /tmp/dependencies.sh && \
    echo $BASE_DEPENDENCIES $GAZEBO_BASE_DEPENDENCIES | tr -d '\\' | xargs apt -q -qq -y install && \
    apt clean && rm -rf /var/lib/apt/lists/
    
## add DART libraries
RUN apt-add-repository -y ppa:dartsim && \
    apt update -q -qq && \
    apt install -q -qq -y libdart6-dev libdart6-utils-urdf-dev && \
    apt clean && rm -rf /var/lib/apt/lists/

#> WORKDIR /build_gazebo
#> RUN git clone https://github.com/osrf/gazebo
#> 
#> WORKDIR /build_gazebo/gazebo
#> RUN git checkout -b build_${_BUILD_GAZEBO_TAG} ${_BUILD_GAZEBO_TAG}
#> 
#> WORKDIR /build_gazebo/gazebo/build
#> RUN cmake -DCMAKE_INSTALL_PREFIX=/usr/local/gazebo ../
#> RUN make -j$(nproc)
#> RUN make install

WORKDIR /
RUN mkdir build_gazebo; cd build_gazebo && \
    git clone https://github.com/osrf/gazebo && \
    cd gazebo && \
    git checkout -b build_${_BUILD_GAZEBO_TAG} ${_BUILD_GAZEBO_TAG} && \
    mkdir build; cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/gazebo ../ && \ 
    make -j$(nproc) && \
    make install && \
    cd /; rm -rf build_gazebo

RUN echo '/usr/local/gazebo/lib' > /etc/ld.so.conf.d/gazebo.conf && ldconfig

ENV LD_LIBRARY_PATH /usr/local/gazebo/lib:${LD_LIBRARY_PATH}
ENV PATH /usr/local/gazebo/bin:${PATH}
ENV PKG_CONFIG_PATH /usr/local/gazebo/lib/pkgconfig:${PKG_CONFIG_PATH}

##
#> WORKDIR /gazebo_ros_pkg_ws/src
#> RUN source /opt/ros/${ROS_DISTRO}/setup.bash && catkin_init_workspace
#> 
#> ## gazebo_ros_pkgs 2.8.7 is latest .deb version of melodic
#> RUN git clone https://github.com/ros-simulation/gazebo_ros_pkgs.git && (cd gazebo_ros_pkgs; git checkout -b build_${_BUILD_GZ_ROS_PKG_TAG} ${_BUILD_GZ_ROS_PKG_TAG} )
#> ## update dependency (may add gazebo files) and remove gazebo files
#> RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
#>     apt update -q -qq && \
#>     rosdep update -q && \
#>     rosdep install -q -r -y --from-paths . --ignore-src && \
#>     apt remove -q -qq -y '.*gazebo.*' '.*sdformat.*' '.*ignition-math.*' '.*ignition-msgs.*' '.*ignition-transport.*' && \
#>     apt autoremove -y && \
#>     wget https://raw.githubusercontent.com/ignition-tooling/release-tools/master/jenkins-scripts/lib/dependencies_archive.sh -O /tmp/dependencies.sh && \
#>     GAZEBO_MAJOR_VERSION=${_BUILD_GAZEBO_VERSION} ROS_DISTRO=${ROS_DISTRO} . /tmp/dependencies.sh && \    
#>     echo $BASE_DEPENDENCIES $GAZEBO_BASE_DEPENDENCIES | tr -d '\\' | xargs apt -q -qq -y install && \    
#>     apt clean && \
#>     rm -rf /var/lib/apt/lists/
#> 
#> WORKDIR /gazebo_ros_pkg_ws
#> RUN source /opt/ros/${ROS_DISTRO}/setup.bash && catkin_make


## gazebo_ros_pkgs 2.8.7 is latest .deb version of melodic
## update dependency (may add gazebo files) and remove gazebo files
## removed by skip-keys
##>>> rosdep install -q -r -y --from-paths . --ignore-src --skip-keys=gazebo9 --skip-keys=libgazebo9-dev && \
# apt remove -s -q -qq -y '.*gazebo.*' '.*sdformat.*' '.*ignition-math.*' '.*ignition-msgs.*' '.*ignition-transport.*' && \
# apt autoremove -y && \
# wget https://raw.githubusercontent.com/ignition-tooling/release-tools/master/jenkins-scripts/lib/dependencies_archive.sh -O /tmp/dependencies.sh && \
# GAZEBO_MAJOR_VERSION=${_BUILD_GAZEBO_VERSION} ROS_DISTRO=${ROS_DISTRO} . /tmp/dependencies.sh && \
# echo $BASE_DEPENDENCIES $GAZEBO_BASE_DEPENDENCIES | tr -d '\\' | xargs apt -q -qq -y install && \
##<<< apt clean && rm -rf /var/lib/apt/lists/ && \
#WORKDIR /gazebo_ros_pkg_ws/src
RUN mkdir -p /gazebo_ros_pkg_ws/src; cd /gazebo_ros_pkg_ws/src && \
    if [ "${ROS_SOURCE}" = "" ]; then source /opt/ros/${ROS_DISTRO}/setup.bash; else source ${ROS_SOURCE}; fi && \
    catkin_init_workspace && \
    git clone https://github.com/ros-simulation/gazebo_ros_pkgs.git && \
    (cd gazebo_ros_pkgs; git checkout -b build_${_BUILD_GZ_ROS_PKG_TAG} ${_BUILD_GZ_ROS_PKG_TAG} ) && \
    apt update -q -qq && \
    rosdep update -q && \
    rosdep install -q -r -y --from-paths . --ignore-src --skip-keys=gazebo9 --skip-keys=libgazebo9-dev && \
    apt clean && rm -rf /var/lib/apt/lists/ && \
    cd /gazebo_ros_pkg_ws && \
    if [ "${ROS_SOURCE}" = "" ]; then source /opt/ros/${ROS_DISTRO}/setup.bash; else source ${ROS_SOURCE}; fi && \
    catkin_make && catkin_make install && \
    rm -rf build devel src
