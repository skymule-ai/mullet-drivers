#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DISPLAY:-}" ]]; then
  echo "DISPLAY must be set (for example, DISPLAY=:0)." >&2
  exit 1
fi

if [[ ! -d /tmp/.X11-unix ]]; then
  echo "The host X11 socket directory /tmp/.X11-unix is unavailable." >&2
  exit 1
fi

docker compose --profile viz run --rm --no-deps viz bash -lc '
  ros2 pkg prefix rviz2
  rviz2 &
  rviz_pid=$!
  sleep 5

  if ! kill -0 "$rviz_pid"; then
    wait "$rviz_pid"
    echo "rviz2 exited before the display smoke test completed." >&2
    exit 1
  fi

  kill -INT "$rviz_pid"
  wait "$rviz_pid"
'
