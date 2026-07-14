#!/usr/bin/env bash
set -euo pipefail

docker compose --env-file .env.example config --quiet
bash -n images/livox/entrypoint.sh images/realsense/entrypoint.sh
