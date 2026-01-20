# ros2_install
Scripts and assets to set up the MSRL ROS 2 workspace (ROS 2 Jazzy + Pylon + required repos).

## Branch purpose
This branch is for safely updating `install_ros2_workspace.sh` and quickly testing it in a Docker container.
Use it only when you are editing the installer and want a clean, repeatable environment.

## Quick container test (this branch)
From the repo root:

```bash
./run_test.sh
```

Optional:

```bash
REBUILD_IMAGE=1 ./run_test.sh
```

## What happens
- Builds a Docker image based on Ubuntu 24.04 with ROS 2 Jazzy preinstalled.
- Mounts this repo into the container at `/ws/src`.
- Runs `/ws/src/install_ros2_workspace.sh` inside the container.
- Reuses your host UID/GID so files created in the container are owned by you.
- If `~/.ssh` exists, it is mounted so the installer can clone private GitHub repos via SSH.

Notes:
- ROS 2 does not need to be installed inside the container; it is already in the image.
- SSH keys are not baked into the image. If `~/.ssh` is missing, the installer offers to create an SSH key for you.
