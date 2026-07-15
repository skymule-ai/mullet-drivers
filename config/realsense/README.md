# RealSense configuration

Store example/default camera parameter files in this directory. Actual serial
numbers, frame IDs, and calibrated transforms belong in the per-drone
configuration repository and are mounted over this directory.

`rs_launch.py` reads its `config_file` as a flat YAML mapping; do not use ROS
`ros__parameters` nesting. Set the ROS topic namespace, camera name, and TF
prefix through the `REALSENSE_CAMERA_NAMESPACE`, `REALSENSE_CAMERA_NAME`, and
`REALSENSE_TF_PREFIX` deployment variables.

The Orin uses librealsense's NEON point-cloud implementation. Configure it
with `pointcloud__neon_.*` keys in this file.
