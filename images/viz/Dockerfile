ARG BASE_IMAGE=ghcr.io/skymule-ai/mullet-ros2-base:v0.2.0
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-humble-rviz2 && \
    rm -rf /var/lib/apt/lists/*

COPY images/viz/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["rviz2"]
