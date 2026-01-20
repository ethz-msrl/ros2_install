FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# Base tools your installer will likely assume exist
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release \
    git build-essential cmake pkg-config \
    python3 python3-pip python3-venv \
    sudo locales tzdata openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Locale (ROS tooling can be picky)
RUN locale-gen en_US en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install ROS 2 Jazzy in the image for faster repeat runs
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends software-properties-common; \
    add-apt-repository universe -y; \
    ROS_APT_SOURCE_VERSION="$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F \"tag_name\" | awk -F\\\" '{print $4}')"; \
    curl -L -o /tmp/ros2-apt-source.deb \
      "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"; \
    dpkg -i /tmp/ros2-apt-source.deb; \
    apt-get update; \
    apt-get install -y --no-install-recommends ros-jazzy-desktop; \
    rm -f /tmp/ros2-apt-source.deb; \
    rm -rf /var/lib/apt/lists/*; \
    echo "source /opt/ros/jazzy/setup.bash" >> /etc/bash.bashrc

# Create a non-root user (robust even if UID/GID already exist)
ARG USER=dev
ARG UID=2000
ARG GID=2000

RUN set -eux; \
    # If a group with GID exists, reuse its name; otherwise create USER group
    if getent group "${GID}" >/dev/null; then \
        EXISTING_GROUP="$(getent group "${GID}" | cut -d: -f1)"; \
        echo "Reusing existing group ${EXISTING_GROUP} (GID=${GID})"; \
        GROUP_NAME="${EXISTING_GROUP}"; \
    else \
        groupadd -g "${GID}" "${USER}"; \
        GROUP_NAME="${USER}"; \
    fi; \
    \
    # If a user with UID exists, reuse it; otherwise create USER with that UID/GID
    if getent passwd "${UID}" >/dev/null; then \
        EXISTING_USER="$(getent passwd "${UID}" | cut -d: -f1)"; \
        echo "Reusing existing user ${EXISTING_USER} (UID=${UID})"; \
        USER_NAME="${EXISTING_USER}"; \
    else \
        useradd -m -u "${UID}" -g "${GID}" -s /bin/bash "${USER}"; \
        USER_NAME="${USER}"; \
    fi; \
    \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >"/etc/sudoers.d/${USER_NAME}"; \
    chmod 0440 "/etc/sudoers.d/${USER_NAME}"

RUN mkdir -p /ws/src && chown -R "${UID}:${GID}" /ws

USER ${USER}
WORKDIR /ws/src
