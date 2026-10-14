#!/usr/bin/env bash
set -e

source /usr/local/share/mullet-ros/setup.bash  # ROS 2 Jazzy + the base workspace (px4_msgs)

exec "$@"
