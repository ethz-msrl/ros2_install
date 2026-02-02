#! /usr/bin/env bash

echo "
███╗   ███╗███████╗██████╗ ██╗     
████╗ ████║██╔════╝██╔══██╗██║     
██╔████╔██║███████╗██████╔╝██║     
██║╚██╔╝██║╚════██║██╔══██╗██║     
██║ ╚═╝ ██║███████║██║  ██║███████╗
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝

██████╗  ██████╗ ███████╗  ██████╗ 
██╔══██╗██╔═══██╗██╔════╝  ╚════██╗
██████╔╝██║   ██║███████╗   █████╔╝
██╔══██╗██║   ██║╚════██║  ██╔═══╝ 
██║  ██║╚██████╔╝███████║  ██████╗ 
╚═╝  ╚═╝ ╚═════╝ ╚══════╝  ╚═════╝ 

██╗    ██╗███████╗
██║    ██║██╔════╝
██║ █╗ ██║███████╗
██║███╗██║╚════██║
╚███╔███╔╝███████║
 ╚══╝╚══╝ ╚══════╝
"

echo
echo "===================================="
echo "Installation Script v1.0.0"
echo "For support contact pernst@student.ethz.ch"
echo "===================================="
echo
echo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ls ~/.ssh/*.pub 2>/dev/null; then
	KEY_FILE=$(ls ~/.ssh/*.pub | head -1)
	echo "public key found in ${KEY_FILE}"
  echo
	echo "Make sure to copy the following and add the key to your GitHub account."
	echo "See https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account"
	echo
	cat ${KEY_FILE}
	echo
	read -p "Press any key to continue"
else
	read -p "No public SSH key was found in ~/.ssh. Should I create one for you? [y]n " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		exit 1
	else
		read -p "Enter your email address: " email
		if ! command -v ssh-keygen >/dev/null 2>&1; then
			echo "ssh-keygen not found; installing openssh-client..."
			if command -v sudo >/dev/null 2>&1; then
				sudo apt update
				sudo apt install -y openssh-client
			else
				apt update
				apt install -y openssh-client
			fi
		fi
		ssh-keygen -t ed25519 -C "$email"
		if [ ! -f ~/.ssh/id_ed25519.pub ]; then
			echo "SSH key generation failed; ~/.ssh/id_ed25519.pub not found."
			exit 1
		fi
        echo
        echo
		echo "Make sure to copy the following and add the key to your GitHub account."
		echo "See https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account"
		echo
		cat ~/.ssh/id_ed25519.pub

		echo
		read -p "Press any key to continue after adding your key to github!"
	fi
fi

echo "Starting ssh-agent"
eval `ssh-agent`
echo "Enter the password that you use in your SSH key"
ssh-add

## Install ROS 2 Jazzy
if [ ! -d "/opt/ros/jazzy" ]; then
  read -p "ROS 2 Jazzy does not seem to be installed on your system. Should I install it for you? [y]n " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    exit 1
  else
    sudo apt update
    sudo apt install -y software-properties-common curl
    sudo add-apt-repository universe -y

    export ROS_APT_SOURCE_VERSION=$(
      curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
        | grep -F "tag_name" | awk -F\" '{print $4}'
    )
    curl -L -o /tmp/ros2-apt-source.deb \
      "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
    sudo dpkg -i /tmp/ros2-apt-source.deb

    sudo apt update
    sudo apt install -y ros-jazzy-desktop

    source /opt/ros/jazzy/setup.bash
  fi
else
  echo "ROS 2 Jazzy is already installed. Sourcing for this session."
  source /opt/ros/jazzy/setup.bash
fi
# Install tools
if [ -f /opt/ros/jazzy/setup.bash ]; then
	source /opt/ros/jazzy/setup.bash
else
	echo "Error: /opt/ros/jazzy/setup.bash not found. Install ROS 2 Jazzy first."
	exit 1
fi

PYLON_REPO_SSH="git@github.com:ethz-msrl/ros2_install.git"
PYLON_REPO_DIR="/tmp/ros2_install_pylon"
PYLON_DEB_REL="Pylon/pylon_*.deb"
if ! dpkg -s pylon >/dev/null 2>&1 && [ ! -d "/opt/pylon" ]; then
	echo "Installing pylon from ${PYLON_REPO_SSH}:${PYLON_DEB_REL}..."
	rm -rf "$PYLON_REPO_DIR"
	if ! command -v git-lfs >/dev/null 2>&1; then
		echo "git-lfs not found; installing git-lfs..."
		if command -v sudo >/dev/null 2>&1; then
			sudo apt-get update
			sudo apt-get install -y git-lfs
		else
			apt-get update
			apt-get install -y git-lfs
		fi
	fi
	if ! git clone "$PYLON_REPO_SSH" "$PYLON_REPO_DIR"; then
		echo "Error: failed to clone ${PYLON_REPO_SSH}."
		exit 1
	fi
	(
		cd "$PYLON_REPO_DIR"
		git lfs install --local
		git lfs pull
	)
	shopt -s nullglob
	pylon_debs=("${PYLON_REPO_DIR}"/${PYLON_DEB_REL})
	shopt -u nullglob
	if [ "${#pylon_debs[@]}" -eq 0 ]; then
		echo "Error: no pylon .deb found at $PYLON_REPO_DIR/$PYLON_DEB_REL."
		rm -rf "$PYLON_REPO_DIR"
		exit 1
	fi
	if command -v sudo >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y "${pylon_debs[@]}"
	else
		apt-get update
		apt-get install -y "${pylon_debs[@]}"
	fi
	rm -rf "$PYLON_REPO_DIR"
fi
if [ -f /opt/pylon/bin/pylon-setup-env.sh ]; then
	source /opt/pylon/bin/pylon-setup-env.sh /opt/pylon
else
	echo "Error: /opt/pylon/bin/pylon-setup-env.sh not found. Pylon install may have failed."
	exit 1
fi
if ! command -v rosdep >/dev/null 2>&1; then
	echo "rosdep not found; installing python3-rosdep..."
	if command -v sudo >/dev/null 2>&1; then
		sudo apt update
		sudo apt install -y python3-rosdep
	else
		apt update
		apt install -y python3-rosdep
	fi
fi
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
	echo "Initializing rosdep..."
	if command -v sudo >/dev/null 2>&1; then
		sudo rosdep init
	else
		rosdep init
	fi
fi
echo "Updating rosdep..."
rosdep update
missing_pkgs=()
if ! command -v colcon >/dev/null 2>&1; then
	missing_pkgs+=("python3-colcon-common-extensions")
fi
if ! command -v swig >/dev/null 2>&1; then
	missing_pkgs+=("swig" "python3-dev")
fi
for pkg in libceres-dev libbenchmark-dev; do
	if ! dpkg -s "$pkg" >/dev/null 2>&1; then
		missing_pkgs+=("$pkg")
	fi
done
for pkg in \
	ros-jazzy-xacro \
	ros-jazzy-v4l2-camera \
	ros-jazzy-vision-opencv \
	ros-jazzy-camera-info-manager \
	ros-jazzy-tf-transformations \
	ros-jazzy-rviz2; do
	if ! dpkg -s "$pkg" >/dev/null 2>&1; then
		missing_pkgs+=("$pkg")
	fi
done
if [ "${#missing_pkgs[@]}" -gt 0 ]; then
	echo "Installing build dependencies: ${missing_pkgs[*]}..."
	if command -v sudo >/dev/null 2>&1; then
		sudo apt update
		sudo apt install -y "${missing_pkgs[@]}"
	else
		apt update
		apt install -y "${missing_pkgs[@]}"
	fi
fi



# Creating ros2_ws
if [ -d "$HOME/ros2_ws" ]; then
	read -r -p "I found $HOME/ros2_ws. Should I install there? [y]n " -n 1 -r
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		exit 1
	else	
		ws_dir=$HOME/ros2_ws
	fi
else
		echo
		echo "I will now create the MSRL ROS 2 workspace"
		read -p "Where should the workspace live (default ~/ros2_ws): " ws_dir
		ws_dir=${ws_dir:-"$HOME/ros2_ws"}

		if [ ! -d "$ws_dir" ]; then
			mkdir "$ws_dir"
		else
			echo "Error: directory $ws_dir already exists"
			exit
		fi
fi
cd "$ws_dir"

#Cloning and building cpp_data_logger_ros2
echo
echo "Getting the cpp_data_logger_ros2 repo from Github"
mkdir -p cpp_data_logger/src
if ! git clone git@github.com:ethz-msrl/cpp_data_logger_ros2.git "$ws_dir/cpp_data_logger/src/cpp_data_logger_ros2"; then
	echo
	echo "Clone failed. This often means your SSH key is not added to GitHub."
	echo "Re-run the script and follow the instuctions to copy your key."
	exit 1
fi
cd cpp_data_logger
if ! colcon build --symlink-install; then
	echo "Build failed for cpp_data_logger_ros2."
	exit 1
fi
source install/setup.bash
cd ..

#Cloning and building ads_ament
echo
echo "Getting the ads_ament repo from Github"
mkdir -p ads_ament/src
if ! git clone git@github.com:ethz-msrl/ads_ament.git "$ws_dir/ads_ament/src/ads_ament"; then
	echo
	echo "Clone failed for ads_ament. This often means your SSH key is not added to GitHub."
	echo "Re-run the script and follow the instuctions to copy your key."
	exit 1
fi
cd ads_ament
if ! colcon build --symlink-install; then
	echo "Build failed for ads_ament."
	exit 1
fi
source install/setup.bash
cd .. 

#Cloning and building Tesla_core_ros2
echo
echo "Getting the Tesla_core_ros2 repo from Github"
mkdir -p tesla_core/src
if ! git clone git@github.com:ethz-msrl/Tesla_core_ros2.git "$ws_dir/tesla_core/src/Tesla_core_ros2"; then
	echo
	echo "Clone failed for Tesla_core_ros2. This often means your SSH key is not added to GitHub."
	echo "Re-run the script and follow the instuctions to copy your key."
	exit 1
fi
cd tesla_core
if ! colcon build --symlink-install; then
	echo "Build failed for Tesla_core_ros2."
	exit 1
fi
source install/setup.bash
cd ..

#Cloning and building Navion_ros2
echo
echo "Getting the Navion_ros2 repo from Github"
mkdir -p navion/src
if ! git clone git@github.com:ethz-msrl/Navion_ros2.git "$ws_dir/navion/src/Navion_ros2"; then
	echo
	echo "Clone failed for Navion_ros2. This often means your SSH key is not added to GitHub."
	echo "Re-run the script and follow the instuctions to copy your key."
	exit 1
fi
cd navion
if ! colcon build --symlink-install; then
	echo "Build failed for Navion_ros2."
	exit 1
fi
source install/setup.bash
cd ..

#Cloning and building Octomag_ros2
echo
echo "Getting the Octomag_ros2 repo from Github"
mkdir -p octomag/src
if ! git clone git@github.com:ethz-msrl/Octomag_ros2.git "$ws_dir/octomag/src/Octomag_ros2"; then
	echo
	echo "Clone failed for Octomag_ros2. This often means your SSH key is not added to GitHub."
	echo "Re-run the script and follow the instuctions to copy your key."
	exit 1
fi
cd octomag
if ! rosdep install --from-paths src --ignore-src -r -y; then
	echo "rosdep install failed for Octomag_ros2."
	exit 1
fi
if ! colcon build --symlink-install; then
	echo "Build failed for Octomag_ros2."
	exit 1
fi
source install/setup.bash
cd ..

#Cloning and building Tesla_ros2
echo
echo "Getting the Tesla_ros2 repo from Github"
mkdir -p tesla/src
if ! git clone git@github.com:ethz-msrl/Tesla_ros2.git "$ws_dir/tesla/src/Tesla_ros2"; then
	echo
	echo "Clone failed for Tesla_ros2. This often means your SSH key is not added to GitHub."
	echo "Re-run the script and follow the instuctions to copy your key."
	exit 1
fi
cd tesla
if ! colcon build --symlink-install; then
	echo "Build failed for Tesla_ros2."
	exit 1
fi
source install/setup.bash
cd ..

overlay_setup="$ws_dir/tesla/install/setup.bash"
if [ -f "$overlay_setup" ]; then
	if ! grep -q "source $overlay_setup" ~/.bashrc; then
		echo "source $overlay_setup" >> ~/.bashrc
	fi
else
	echo "Warning: overlay setup not found at $overlay_setup"
fi
if ! grep -q "RCUTILS_COLORIZED_OUTPUT" ~/.bashrc; then
	echo "export RCUTILS_COLORIZED_OUTPUT=1" >> ~/.bashrc
fi

echo
echo "===================================="
echo "Installation Summary"
echo "===================================="
if [ -d "/opt/ros/jazzy" ]; then
	echo "ROS 2 Jazzy: /opt/ros/jazzy (OK)"
else
	echo "ROS 2 Jazzy: /opt/ros/jazzy (MISSING)"
fi
if [ -d "/opt/pylon" ]; then
	echo "Pylon: /opt/pylon (OK)"
else
	echo "Pylon: /opt/pylon (MISSING)"
fi
if [ -d "$ws_dir" ]; then
	echo "Workspace: $ws_dir (OK)"
else
	echo "Workspace: $ws_dir (MISSING)"
fi
for repo_dir in \
	"$ws_dir/cpp_data_logger/src/cpp_data_logger_ros2" \
	"$ws_dir/ads_ament/src/ads_ament" \
	"$ws_dir/tesla_core/src/Tesla_core_ros2" \
	"$ws_dir/navion/src/Navion_ros2" \
	"$ws_dir/octomag/src/Octomag_ros2" \
	"$ws_dir/tesla/src/Tesla_ros2"; do
	if [ -d "$repo_dir" ]; then
		echo "Repo: $repo_dir (OK)"
	else
		echo "Repo: $repo_dir (MISSING)"
	fi
done
if [ -f "$overlay_setup" ]; then
	echo "Overlay setup: $overlay_setup (OK)"
else
	echo "Overlay setup: $overlay_setup (MISSING)"
fi
