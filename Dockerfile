FROM osrf/ros:melodic-desktop-full

RUN apt update -q -qq && \
    apt install -q -qq -y python-pip ros-${ROS_DISTRO}-catkin python-wstools python-catkin-tools && \
    apt install -q -qq -y less emacs && \
    apt clean && \
    rm -rf /var/lib/apt/lists/

WORKDIR /catkin_ws
COPY dot.rosinstall .
RUN wstool init src dot.rosinstall

COPY s-noda_euslib src/s-noda_euslib


WORKDIR /catkin_ws/src

RUN for pkg in eus_caffe hrpsys_ros_bridge_jvrc hrpsys_choreonoid_tutorials choreonoid hrpsys_gazebo_tutorials; do (cd $(find . -type d -name ${pkg} | head -n 1); touch CATKIN_IGNORE); done

RUN apt update -q -qq && \
    (rosdep install -q -r -y --from-paths . --ignore-src || echo 'Ignore_rosdep_error') && \
    apt clean && \
    rm -rf /var/lib/apt/lists/

WORKDIR /catkin_ws

RUN bash -c "source /opt/ros/melodic/setup.bash; catkin init"
RUN bash -c "source /opt/ros/melodic/setup.bash; catkin build -c --no-notify || echo 'Ignore error'"
