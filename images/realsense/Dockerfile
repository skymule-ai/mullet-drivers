ARG BASE_IMAGE=ghcr.io/skymule-ai/mullet-ros2-base:v0.2.0
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG LIBREALSENSE_REF=5330e760a266d19c7e1e7ec7ada8caa4ff8b3196
ARG REALSENSE_ROS_REF=926f37e01f4f53186fc1817aba36713442d98b3e

LABEL org.opencontainers.image.title="mullet ROS Intel RealSense D435i driver"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libgl1-mesa-dev \
      libssl-dev \
      libudev-dev \
      libusb-1.0-0-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

# RSUSB accesses the D435i through USB userspace and does not require installing
# a patched host kernel module from inside the container.
WORKDIR /opt
RUN git clone https://github.com/realsenseai/librealsense.git && \
    cd librealsense && \
    git checkout --detach ${LIBREALSENSE_REF} && \
    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_GRAPHICAL_EXAMPLES=OFF \
      -DFORCE_RSUSB_BACKEND=ON && \
    cmake --build build --parallel "$(nproc)" && \
    cmake --install build && \
    ldconfig && \
    rm -rf /opt/librealsense

WORKDIR /opt/realsense_ws
RUN mkdir -p src && \
    git clone https://github.com/realsenseai/realsense-ros.git src/realsense-ros && \
    cd src/realsense-ros && \
    git checkout --detach ${REALSENSE_ROS_REF} && \
    source /opt/ros/humble/setup.bash && \
    apt-get update && \
    rosdep install --from-paths . --ignore-src -r -y --skip-keys librealsense2 && \
    cd /opt/realsense_ws && \
    colcon build --merge-install \
      --packages-select realsense2_camera_msgs realsense2_description realsense2_camera \
      --cmake-args -DBUILD_ACCELERATE_GPU_WITH_GLSL=ON && \
    source install/setup.bash && \
    ros2 pkg prefix realsense2_camera && \
    rm -rf /var/lib/apt/lists/*

COPY images/realsense/entrypoint.sh /usr/local/bin/mullet-realsense-entrypoint
COPY images/realsense/profile.sh /etc/profile.d/10-mullet-realsense.sh
RUN chmod 0755 /usr/local/bin/mullet-realsense-entrypoint && \
    chmod 0644 /etc/profile.d/10-mullet-realsense.sh

ENTRYPOINT ["/usr/local/bin/mullet-realsense-entrypoint"]
CMD ["ros2", "launch", "realsense2_camera", "rs_launch.py", "config_file:=/config/d435i.yaml"]
