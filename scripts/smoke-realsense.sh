#!/usr/bin/env bash
set -euo pipefail

docker compose run --rm realsense bash -lc '
  ros2 pkg prefix realsense2_camera
  ldconfig -p | grep -q librealsense2
  ros2 launch realsense2_camera rs_launch.py --show-args > /dev/null
'
