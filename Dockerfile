FROM nvidia/cuda:11.6.1-cudnn8-devel-ubuntu20.04
ARG ROS_DISTRO=noetic
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# ===
# Basic Installation
# ===
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo git \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
RUN apt-get update && apt-get upgrade -y

# ===
# ROS Installation
# ===
RUN apt-get update && apt-get install -y lsb-release curl
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-desktop \
    python3-catkin-tools
RUN rm -rf /var/lib/apt/lists/*
RUN rm /etc/apt/apt.conf.d/docker-clean

# ===
# ROS Setting
# ===
USER $USERNAME
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
RUN echo "source ~/ws/devel/setup.bash" >> ~/.bashrc
RUN echo "export ROS_DISTRO=${ROS_DISTRO}" >> ~/.bashrc
RUN echo "export ROS_WORKSPACE=~/ws" >> ~/.bashrc
RUN echo "export ROS_PACKAGE_PATH=~/ws/src:\$ROS_PACKAGE_PATH" >> ~/.bashrc
RUN echo "export ROSCONSOLE_FORMAT='[\${severity}] [\${time}] [\${node}]: \${message}'" >> ~/.bashrc

# ===
# OpenCV Installation
# ===
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    wget \
    unzip \
    libgtk2.0-dev \
    pkg-config
RUN cd ~/ \
    && wget -O opencv.zip https://github.com/opencv/opencv/archive/4.7.0.zip \
    && unzip opencv.zip \
    && cd opencv-4.7.0 \
    && cmake -S . -B build \
    && cmake --build build -- -j4 \
    && cd build \
    && sudo make install \
    && rm ~/opencv.zip

# ===
# YOLOv8 Installation
# ===
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends python3-pip
RUN cd ~/ \
    && git clone https://github.com/ultralytics/ultralytics.git \
    && cd ultralytics \
    && pip install .
RUN cd ~/ \
    && ~/.local/bin/yolo export model=yolov8s.pt imgsz=480,640 format=onnx opset=12


ENV SHELL /bin/bash
CMD ["/bin/bash"]
