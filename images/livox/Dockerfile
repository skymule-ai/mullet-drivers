ARG BASE_IMAGE=ghcr.io/skymule-ai/mullet-ros2-base:v0.4.0
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG LIVOX_SDK2_REF=f5d9375f84efe2b15bc0a052d3e18482ed13adf4
ARG LIVOX_ROS_DRIVER2_REF=13eb05e4e6dd7a765b934d0c5fd6236676a57b49

LABEL org.opencontainers.image.title="mullet ROS Livox MID-360 driver"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libboost-system-dev \
      libpcl-dev \
      ros-humble-ament-cmake-auto \
      ros-humble-perception-pcl \
      libyaml-cpp-dev && \
    rm -rf /var/lib/apt/lists/*

# Livox SDK2 provides the MID-360 transport used by livox_ros_driver2.
WORKDIR /opt
RUN git clone https://github.com/Livox-SDK/Livox-SDK2.git Livox-SDK2 && \
    cd Livox-SDK2 && \
    git checkout --detach ${LIVOX_SDK2_REF} && \
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --parallel "$(nproc)" && \
    cmake --install build && \
    ldconfig && \
    rm -rf /opt/Livox-SDK2

WORKDIR /opt/livox_ws
RUN mkdir -p src && \
    git clone https://github.com/Livox-SDK/livox_ros_driver2.git src/livox_ros_driver2 && \
    cd src/livox_ros_driver2 && \
    git checkout --detach ${LIVOX_ROS_DRIVER2_REF} && \
    source /opt/ros/humble/setup.bash && \
    ./build.sh humble && \
    source install/setup.bash && \
    ros2 pkg prefix livox_ros_driver2

COPY images/livox/entrypoint.sh /usr/local/bin/mullet-livox-entrypoint
COPY images/livox/profile.sh /etc/profile.d/10-mullet-livox.sh
RUN chmod 0755 /usr/local/bin/mullet-livox-entrypoint && \
    chmod 0644 /etc/profile.d/10-mullet-livox.sh

ENTRYPOINT ["/usr/local/bin/mullet-livox-entrypoint"]
CMD ["ros2", "run", "livox_ros_driver2", "livox_ros_driver2_node", "--ros-args", "-p", "xfer_format:=0", "-p", "multi_topic:=0", "-p", "data_src:=0", "-p", "publish_freq:=10.0", "-p", "output_data_type:=0", "-p", "frame_id:=livox_frame", "-p", "user_config_path:=/config/MID360_config.json"]
