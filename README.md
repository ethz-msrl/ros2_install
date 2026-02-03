# ros2_install
Scripts and assets to set up the MSRL ROS 2 workspace (ROS 2 Jazzy + Pylon + required repos).

## Quick installation script (no clone)
Copy this one-liner into a Ubuntu terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/ethz-msrl/ros2_install/main/install_ros2_workspace.sh)
```

## What the installer does (step by step)
The `install_ros2_workspace.sh` script performs the following actions in order:

1. Prints a banner and basic version/support info.
2. Checks for an existing SSH public key in `~/.ssh`.
   - If a key exists, it prints it and asks you to add it to GitHub.
   - If no key exists, it offers to generate an ed25519 key and then asks you to add it to GitHub.
3. Starts `ssh-agent` and runs `ssh-add` so GitHub SSH clones work.
4. Ensures ROS 2 Jazzy is installed.
   - If `/opt/ros/jazzy` is missing, it installs the ROS 2 apt source and `ros-jazzy-desktop`.
   - If it is present, it simply sources `/opt/ros/jazzy/setup.bash` for this session.
5. Ensures Pylon is installed.
   - If `pylon` is missing, it clones this repo to `/tmp`, pulls the large Pylon `.deb` via Git LFS,
     and installs it using `apt`.
   - It then sources `/opt/pylon/bin/pylon-setup-env.sh`.
6. Installs build and runtime dependencies if they are missing:
   - `python3-colcon-common-extensions`, `swig`, `python3-dev`, `libceres-dev`, `libbenchmark-dev`
   - `ros-jazzy-xacro`, `ros-jazzy-v4l2-camera`, `ros-jazzy-vision-opencv`,
     `ros-jazzy-camera-info-manager`, `ros-jazzy-tf-transformations`, `ros-jazzy-rviz2`
7. Creates a ROS 2 workspace directory.
   - If `~/ros2_ws` exists, it asks to use it.
   - Otherwise it prompts for a path (default: `~/ros2_ws`) and creates it.
8. Clones and builds each repository into its own sub-workspace:
   - `cpp_data_logger_ros2`
   - `ads_ament`
   - `Tesla_core_ros2`
   - `Navion_ros2`
   - `Octomag_ros2`
   - `Tesla_ros2`
   Each one is built with `colcon build --symlink-install`, and after each build the script
   sources the corresponding `install/setup.bash` to overlay the environment for the next build.
9. Adds the final overlay and colorized output to your shell startup:
   - It appends `source <ws>/tesla/install/setup.bash` to `~/.bashrc` if not already present.
   - It appends `export RCUTILS_COLORIZED_OUTPUT=1` to `~/.bashrc` if not already present.
10. Prints a summary of what was installed and which repositories are present.

## Overlay behavior and how to use it
Each `colcon build --symlink-install` creates an `install/setup.bash` in that sub-workspace. The
installer sources these in sequence, which overlays each workspace on top of the previous one.
This ensures later builds can find the packages from earlier builds.

At the end, the script registers the final overlay (`<ws>/tesla/install/setup.bash`) in `~/.bashrc`.
That means:
- You do not need to manually source anything after running the installer.
- New terminals will automatically have the full overlay active.
- The installer already sourced the overlays during the run, so the current session is also set up.
  If you want to reapply it manually, you can run `source ~/.bashrc`, but it should not be required.

## Update install shell script
To update, change or adjust the shell script go into the develop branch.
In the develop branch you can find a script that opens a docker container and runs the install script in there for testing.
