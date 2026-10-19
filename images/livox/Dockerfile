ARG BASE_IMAGE=ghcr.io/skymule-ai/mullet-base:v0.5.1
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG LIVOX_SDK2_REF=f5d9375f84efe2b15bc0a052d3e18482ed13adf4
ARG LIVOX_ROS_DRIVER2_REF=13eb05e4e6dd7a765b934d0c5fd6236676a57b49

LABEL org.opencontainers.image.title="mullet ROS Livox MID-360 driver"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cmake \
      git \
      libboost-system-dev \
      libpcl-dev \
      libyaml-cpp-dev \
      linuxptp && \
    rm -rf /var/lib/apt/lists/*

# ── Livox SDK2 ────────────────────────────────────────────────────────────────
# SDK2 uses std::uint8_t without <cstdint>, which GCC 13 (Ubuntu 24.04) no longer
# pulls in transitively.
WORKDIR /opt

RUN git clone https://github.com/Livox-SDK/Livox-SDK2.git && \
    cd Livox-SDK2 && \
    git checkout "${LIVOX_SDK2_REF}" && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_CXX_FLAGS="-include cstdint" && \
    make -j"$(nproc)" && \
    make install && \
    cd /opt && \
    rm -rf Livox-SDK2

# ── livox_ros_driver2 (ROS 2 Jazzy) ──────────────────────────────────────────
# The driver ships per-ROS-version manifests; build.sh only copies the ROS 2 one
# into place and calls colcon, so do both here. rosdep installs its ROS deps
# (pcl_conversions, pcl_msgs, ...) for the base image's distro.
WORKDIR /opt/livox_ws

RUN mkdir -p src && \
    cd src && \
    git clone https://github.com/Livox-SDK/livox_ros_driver2.git && \
    cd livox_ros_driver2 && \
    git checkout "${LIVOX_ROS_DRIVER2_REF}" && \
    cp package_ROS2.xml package.xml && \
    cd /opt/livox_ws && \
    source /usr/local/share/mullet-ros/setup.bash && \
    apt-get update && \
    rosdep install --from-paths src --ignore-src -r -y && \
    rm -rf /var/lib/apt/lists/* && \
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release \
      -DROS_EDITION=ROS2 -DDISTRO_ROS=${ROS_DISTRO} && \
    rm -rf build log

# /livox/lidar is livox_ros_driver2/msg/CustomMsg (xfer_format 1): per-point offset times, which
# FAST-LIO needs to deskew the scan. Images that consume it copy /opt/livox_ws/install and the SDK
# library from this image (COPY --from), so the message type and its Jazzy type hash stay identical.
# ptp4l is here for the livox-ptp service: synced, the MID-360 stamps at measurement, not on arrival.
# The MID-360 syncs to gPTP (livox-gptp.cfg), not to ptp4l's default IEEE 1588 over UDP.
# livox-status reads the sync state the LiDAR itself reports.
COPY images/livox/livox-gptp.cfg /etc/linuxptp/livox-gptp.cfg
COPY images/livox/livox-status.py /usr/local/bin/livox-status
COPY images/livox/entrypoint.sh /usr/local/bin/mullet-livox-entrypoint
COPY images/livox/profile.sh /etc/profile.d/10-mullet-livox.sh

RUN chmod 0755 /usr/local/bin/mullet-livox-entrypoint /usr/local/bin/livox-status && \
    chmod 0644 /etc/profile.d/10-mullet-livox.sh

ENTRYPOINT ["/usr/local/bin/mullet-livox-entrypoint"]
CMD ["ros2", "run", "livox_ros_driver2", "livox_ros_driver2_node", "--ros-args", "-p", "xfer_format:=1", "-p", "multi_topic:=0", "-p", "data_src:=0", "-p", "publish_freq:=10.0", "-p", "output_data_type:=0", "-p", "frame_id:=livox_frame", "-p", "user_config_path:=/config/MID360s_config.json"]
