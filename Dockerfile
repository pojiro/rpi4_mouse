FROM arm64v8/ros:jazzy-ros-core

RUN apt-get update && \
    apt-get install -y \
      ros-jazzy-rmw-zenoh-cpp ros-jazzy-raspimouse && \
      rm -rf /var/lib/apt/lists/*
