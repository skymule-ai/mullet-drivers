#!/usr/bin/env bash
set -euo pipefail

docker compose --env-file .env.example config --quiet
bash -n images/livox/entrypoint.sh images/livox/profile.sh images/realsense/entrypoint.sh images/realsense/profile.sh images/viz/entrypoint.sh scripts/smoke-viz.sh
