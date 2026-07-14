# mullet_ros_drivers

ROS 2 sensor-driver images for the Mullet Jetson platform. Each driver image
extends an immutable release of `mullet-ros2-base`; the driver repository does
not modify the base image or store aircraft-specific calibration.

## Layout

```text
images/livox/       Livox SDK2 + livox_ros_driver2 image for MID-360
images/realsense/   librealsense + realsense-ros image for D435i
images/viz/         optional local RViz image
config/             Defaults and examples only
compose.yaml        Select drivers through Compose profiles
```

## Base-image contract

All images use the base release selected by `BASE_IMAGE` in `.env`:

```dotenv
BASE_IMAGE=ghcr.io/skymule-ai/mullet-ros2-base:v0.1.0
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
PointCloud2 without launching RViz. CUDA is available for downstream
perception nodes; neither vendor driver automatically moves its point-cloud
generation onto CUDA.

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

## Responsibilities

- This repository owns reusable driver source, image builds, launch defaults,
  and example configuration.
- A future per-drone configuration repository owns sensor serial numbers/IPs,
  calibration, frame transforms, and the set of profiles enabled on that
  aircraft.

## Hardware access

Livox uses host networking and should not need broad device access. RealSense
uses librealsense's RSUSB backend and is given USB access only. Both images
inherit CUDA 12.6 from the base and run with the NVIDIA runtime for downstream
GPU processing. Do not add `privileged: true` or mount all of `/dev`.

## Build and test on the Orin

```bash
cp .env.example .env
docker compose --profile livox build
./scripts/smoke-livox.sh

docker compose --profile realsense build
./scripts/smoke-realsense.sh
```

Connect each sensor before its runtime test. After the images have been
published, run the selected profile with `docker compose --profile livox up`
or `docker compose --profile realsense up`.

## CI and image tags

CI builds Livox and RealSense independently on ARM64. Branch pushes publish
SHA-tagged test images; release tags publish matching immutable driver tags.
Both CI builds use `mullet-ros2-base:v0.1.0`.
