#!/usr/bin/env bash
set -euo pipefail

docker compose run --rm livox bash -lc '
  ros2 pkg prefix livox_ros_driver2
  ldconfig -p | grep -q livox_lidar_sdk_shared
  ros2 pkg executables livox_ros_driver2 | grep -q livox_ros_driver2_node  # the node ignores --help and runs
'
