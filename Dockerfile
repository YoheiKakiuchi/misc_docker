## osrf/ros:melodic-desktop
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

LABEL maintainer "YoheiKakiuchi <kakiuchi.yohei.sw@tut.jp>"

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

### install choreonoid
WORKDIR /choreonoid_ws
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    wstool init src && \
    wstool set -y -t src choreonoid https://github.com/choreonoid/choreonoid.git -v release-1.7 --git && \
    wstool update -t src

RUN apt update -q -qq && \
    sed -i -e 's@sudo apt-get -y install@apt-get install -y -q -qq @g' src/choreonoid/misc/script/install-requisites-ubuntu-18.04.sh && \
    src/choreonoid/misc/script/install-requisites-ubuntu-18.04.sh && \
    apt install -q -qq -y curl python-catkin-tools ros-${ROS_DISTRO}-openrtm-aist ros-${ROS_DISTRO}-openrtm-aist-python && \
    apt clean && \
    rm -rf /var/lib/apt/lists/

#RUN patch -p1 -d src/choreonoid < src/rtmros_choreonoid/choreonoid.patch
RUN curl -sL https://github.com/start-jsk/rtmros_choreonoid/raw/master/choreonoid.patch | patch -p1 -d src/choreonoid

RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && catkin config --install && catkin build choreonoid --no-status --no-notify -p 1 && catkin clean -b -l -y"

### install rtmros_choreonoid
ENV MY_ROSWORKSPACE /catkin_ws
WORKDIR ${MY_ROSWORKSPACE}

##  wstool set -y -t src rtmros_choreonoid https://github.com/start-jsk/rtmros_choreonoid --git && \    
RUN source /choreonoid_ws/install/setup.bash && \
    wstool init src && \
    wstool set -y -t src rtmros_choreonoid https://github.com/YoheiKakiuchi/rtmros_choreonoid -v fix_footsal --git && \
    wstool set -y -t src rtmros_tutorials https://github.com/start-jsk/rtmros_tutorials.git --git && \
    wstool set -y -t src jsk_robot https://github.com/jsk-ros-pkg/jsk_robot.git --git && \
    wstool set -y -t src jsk_control https://github.com/jsk-ros-pkg/jsk_control.git --git && \
    wstool update -t src && \
    (cd src/jsk_robot; rm -rf jsk_aero_robot jsk_baxter_robot jsk_denso_robot jsk_fetch_robot jsk_kinova_robot jsk_magni_robot jsk_naoqi_robot jsk_pr2_robot ) && \
    (cd src/rtmros_tutorials; rm -rf hrpsys_gazebo_tutorials hironx_tutorial hrpsys_tutorials openhrp3_tutorials)

RUN source /choreonoid_ws/install/setup.bash && \
    apt update -q -qq && \
    apt install -q -qq -y ros-${ROS_DISTRO}-jsk-tilt-laser ros-${ROS_DISTRO}-jsk-recognition ros-${ROS_DISTRO}-pr2-navigation-self-filter && \
    (rosdep install -n -q -y -r --from-paths src --ignore-src --skip-keys libpng12-dev --skip-keys leap_motion || echo 'Ignore_rosdep_error') && \
    apt clean && \
    rm -rf /var/lib/apt/lists/

RUN /bin/bash -c "source /choreonoid_ws/install/setup.bash && catkin build hrpsys_choreonoid_tutorials jsk_robot_startup --no-status --no-notify -j 1 -p 1 && catkin clean -b -l -y"

### ADD entry point
