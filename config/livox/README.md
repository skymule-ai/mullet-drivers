# Livox configuration

Store example/default Livox JSON configuration in this directory. Actual
vehicle-specific IP addresses, frame IDs, and calibration belong in the
per-drone configuration repository and are mounted over this directory.

`MID360_config.json` is a template, not a ready-to-run network configuration.
Before launching, set its host IP addresses to the Jetson interface connected
to the LiDAR and set `lidar_configs[0].ip` to the MID-360 address. The image
publishes `sensor_msgs/PointCloud2` using `xfer_format=0`.
