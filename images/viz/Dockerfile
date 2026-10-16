ARG BASE_IMAGE=ghcr.io/skymule-ai/mullet-ros2-base:v0.5.0
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# RViz for a display on the Orin; foxglove_bridge (ws://<drone>:8765) for Lichtblick
# or Foxglove on the ground station, which only streams the topics a panel uses.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-foxglove-bridge \
        ros-${ROS_DISTRO}-rviz2 && \
    rm -rf /var/lib/apt/lists/*

COPY images/viz/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["rviz2"]
