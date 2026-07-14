#!/usr/bin/env bash
set -e

source /opt/ros/humble/setup.bash
source /opt/ros2_base_ws/install/setup.bash
source /opt/livox_ws/install/setup.bash

exec "$@"
