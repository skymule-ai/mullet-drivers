# Livox configuration

`MID360s_config.json` is the example the image loads (`user_config_path:=/config/MID360s_config.json`).
A drone's real file, with its addresses, lives in mullet-localization and is mounted over this
directory.

- **Model block.** Livox SDK2 reads only the block named after the connected model: `"Mid360s"` for
  a Mid-360S, `"MID360"` for a Mid-360 (both `lidar_type: 8`). The wrong name means the SDK never
  sends the LiDAR the host's address, and no data arrives. Check the label on the housing, or the
  device type the driver logs at start-up.
- **Addresses.** The LiDAR's factory IP is `192.168.1.1<last two digits of its serial>`;
  `sudo tcpdump -ni <iface> udp port 56000` shows its broadcasts. `host_ip` is the Orin's interface
  wired to it (192.168.1.50/24 on the USB Ethernet adapter).
- **Extrinsics** stay at zero: points come out in the LiDAR frame, and the LiDAR-to-IMU and
  body extrinsics belong to the estimator's config.
