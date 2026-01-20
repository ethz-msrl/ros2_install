#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS_DIR="${ROOT_DIR}"
IMAGE="ros2-jazzy-test:ubuntu24"
SCRIPT="/ws/src/install_ros2_workspace.sh"
SSH_DIR="${HOME}/.ssh"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
REBUILD_IMAGE="${REBUILD_IMAGE:-0}"

if sudo docker ps -a --format '{{.Names}}' | grep -qx 'ros2_jazzy_installer_test'; then
  sudo docker rm -f ros2_jazzy_installer_test
fi

if [ "${REBUILD_IMAGE}" -eq 1 ] || ! sudo docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  sudo docker build \
    --build-arg UID="${HOST_UID}" \
    --build-arg GID="${HOST_GID}" \
    -t "${IMAGE}" \
    "${ROOT_DIR}"
fi

DOCKER_ARGS=(
  --rm -it
  --name ros2_jazzy_installer_test
  -v "${WS_DIR}:/ws/src"
)
if [ -d "${SSH_DIR}" ]; then
  DOCKER_ARGS+=(-v "${SSH_DIR}:/home/dev/.ssh")
fi

sudo docker run "${DOCKER_ARGS[@]}" \
  "${IMAGE}" \
  bash -lc "${SCRIPT} $*"
