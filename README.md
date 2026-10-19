# mullet-drivers

ROS 2 Jazzy sensor-driver images for the Mullet Jetson platform. Each driver image
extends an immutable release of `mullet-base`; the driver repository does
not modify the base image or store aircraft-specific calibration.

## Layout

```text
images/livox/       Livox SDK2 + livox_ros_driver2 image for MID-360
images/realsense/   librealsense + realsense-ros image for D435i
images/viz/         optional RViz + foxglove_bridge image
config/             Defaults and examples only
compose.yaml        Select drivers through Compose profiles
```

## Base-image contract

All images use the base release selected by `BASE_IMAGE` in `.env`:

```dotenv
BASE_IMAGE=ghcr.io/skymule-ai/mullet-base:v0.5.1
```

Use a release tag, never `main`, for driver builds intended for a drone.

## Profiles

```bash
cp .env.example .env
docker compose --profile livox build
docker compose --profile realsense build
docker compose --profile viz build
```

Both images build pinned upstream source revisions. Update a source pin only
after hardware validation on the target Orin.

The D435i launch enables color, depth, accelerometer, gyroscope, synchronized
frames, aligned depth, and a textured PointCloud2. The MID-360 image publishes
`/livox/lidar` as `livox_ros_driver2/msg/CustomMsg` and `/livox/imu` (accelerations in g), without RViz. CUDA is available for downstream
perception nodes; neither vendor driver automatically moves its point-cloud
generation onto CUDA.

The RealSense topics default to `/uav0/d435i/...`. Set
`REALSENSE_CAMERA_NAMESPACE`, `REALSENSE_CAMERA_NAME`, and
`REALSENSE_TF_PREFIX` in the per-vehicle deployment configuration to avoid
topic and TF-frame collisions between aircraft.

For interactive inspection, use `docker compose exec <service> bash -l`.
The login shell loads ROS 2 Jazzy, the base workspace, and the selected driver
overlay, so `ros2` commands need no manual `source` steps.

The optional `viz` profile runs RViz on a display connected to the Orin. It is
not part of the default profile set. On an X11 desktop, permit the local root
container to use the display before starting it:

```bash
xhost +si:localuser:root
docker compose --profile livox --profile viz up
```

The `viz` service uses the host X11 socket and the NVIDIA graphics runtime.
Run `xhost -si:localuser:root` when finished. For flight use, leave `viz` off;
use a ground-station RViz instance instead.

Without a display on the Orin, the `foxglove` profile runs foxglove_bridge from
the same image. Open Lichtblick or Foxglove on the ground station and connect to
`ws://<drone-ip>:8765`. The bridge streams only the topics a panel subscribes to;
a raw MID-360 cloud is about 5 MB/s over WiFi.

## MID-360

- **Network.** The LiDAR talks UDP to a fixed host address. On the Orin, give the interface wired
  to it a static address and no default route:
  `sudo nmcli con add type ethernet ifname <iface> con-name livox ipv4.method manual
  ipv4.addresses 192.168.1.50/24 ipv4.never-default yes ipv6.method disabled`.
  See [config/livox/README.md](config/livox/README.md) for the model block and the LiDAR's IP.
- **CustomMsg, not PointCloud2.** `/livox/lidar` carries per-point offset times, which LIO needs
  to deskew a scan. Foxglove and RViz cannot draw it: view an estimator's cloud (FAST-LIO's
  `cloud_registered_body`), or run the driver with `xfer_format:=0` for raw PointCloud2.
- **Time.** The driver stamps messages with the LiDAR's clock, which counts from power-on until
  a PTP master sets it. The `livox-ptp` service (profile `livox`) runs `ptp4l` as master on
  `LIVOX_IFACE`, with software timestamping. It never steers the host clock. Check that
  `/livox/imu` header stamps match the host's clock (mullet-localization's `scripts/test-on-orin.sh`
  prints the offset).
- **Using the Livox messages in another image.** Copy them from this image; do not rebuild the
  SDK or driver. The message type and its Jazzy type hash then match the driver exactly:

  ```dockerfile
  ARG LIVOX_IMAGE=ghcr.io/skymule-ai/mullet-drivers-livox:v0.5.0
  FROM ${LIVOX_IMAGE} AS livox
  FROM ${BASE_IMAGE}
  COPY --from=livox /opt/livox_ws/install /opt/livox_ws/install
  COPY --from=livox /usr/local/lib/liblivox_lidar_sdk_shared.so /usr/local/lib/
  ```

  Then source `/opt/livox_ws/install/setup.bash`. Use the same `mullet-base` release as this image.

## Responsibilities

- This repository owns reusable driver source, image builds, launch defaults,
  and example configuration.
- A future per-drone configuration repository owns sensor serial numbers/IPs,
  calibration, frame transforms, and the set of profiles enabled on that
  aircraft.

## Hardware access

Livox uses host networking and should not need broad device access. RealSense
uses librealsense's RSUSB backend and is given USB access only. Both images
inherit CUDA 13.2 from the base and run with the NVIDIA runtime for downstream
GPU processing. Do not add `privileged: true` or mount all of `/dev`.

## Build and test on the Orin

```bash
cp .env.example .env
docker compose --profile livox build
./scripts/smoke-livox.sh

docker compose --profile realsense build
./scripts/smoke-realsense.sh

# Requires an X11 display attached to the Orin.
xhost +si:localuser:root
docker compose --profile viz build
DISPLAY=:0 ./scripts/smoke-viz.sh
xhost -si:localuser:root
```

Connect each sensor before its runtime test. After the images have been
published, run the selected profile with `docker compose --profile livox up`,
`docker compose --profile realsense up`, or `docker compose --profile viz up`.
The RViz smoke test starts RViz briefly and confirms that it remains connected
to the local X11 display; defer it on headless Orins.

## CI and image tags

CI builds the Livox, RealSense and viz images independently on ARM64. Branch pushes publish
SHA-tagged test images; release tags publish matching immutable driver tags.
All CI builds use `mullet-base:v0.5.1` (ROS 2 Jazzy, like mullet-core).
Images are `ghcr.io/skymule-ai/mullet-drivers-{livox,realsense,viz}`; tags up to
`v0.3.0` are the Humble images, published as `mullet-ros-{livox,realsense}`.
