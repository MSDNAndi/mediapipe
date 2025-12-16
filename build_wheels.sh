#!/bin/bash
# Copyright 2025 The MediaPipe Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script to build MediaPipe Python wheels locally using Docker
# Usage: ./build_wheels.sh [PLATFORM] [PYTHON_VERSION]
#   PLATFORM: x86_64 (default), aarch64
#   PYTHON_VERSION: cp312-cp312 (default), cp39-cp39, cp310-cp310, cp311-cp311, cp313-cp313

set -e

PLATFORM=${1:-x86_64}
PYTHON_VERSION=${2:-cp312-cp312}

# Map Python version identifiers to actual versions
case $PYTHON_VERSION in
  cp39-cp39)
    PYTHON_BIN_VERSION="3.9"
    ;;
  cp310-cp310)
    PYTHON_BIN_VERSION="3.10"
    ;;
  cp311-cp311)
    PYTHON_BIN_VERSION="3.11"
    ;;
  cp312-cp312)
    PYTHON_BIN_VERSION="3.12"
    ;;
  cp313-cp313)
    PYTHON_BIN_VERSION="3.13"
    ;;
  *)
    echo "Unknown Python version: $PYTHON_VERSION"
    echo "Supported versions: cp39-cp39, cp310-cp310, cp311-cp311, cp312-cp312, cp313-cp313"
    exit 1
    ;;
esac

printf "Building MediaPipe wheel for %s with Python %s\n" "$PLATFORM" "$PYTHON_BIN_VERSION"
printf "==================================================\n"

if [ "$PLATFORM" == "x86_64" ]; then
  DOCKERFILE="Dockerfile.manylinux_2_28_x86_64"
  IMAGE_TAG="mp_manylinux_${PYTHON_VERSION}"

  printf "Building Docker image...\n"
  DOCKER_BUILDKIT=1 docker build \
    -f "$DOCKERFILE" \
    -t "$IMAGE_TAG":latest \
    --build-arg PYTHON_BIN="/opt/python/${PYTHON_VERSION}/bin/python${PYTHON_BIN_VERSION}" \
    .
elif [ "$PLATFORM" == "aarch64" ]; then
  DOCKERFILE="Dockerfile.manylinux2014_aarch64rp4"
  IMAGE_TAG="mp_manylinux_aarch64rp4"

  printf "Building Docker image for ARM64 (this may take a while)...\n"
  docker build \
    -f "$DOCKERFILE" \
    -t "$IMAGE_TAG":latest \
    .

else
  printf "Unknown platform: %s\n" "$PLATFORM"
  printf "Supported platforms: x86_64, aarch64\n"
  exit 1
fi

printf "\nExtracting wheel from container...\n"
docker create -ti --name mp_pip_package_container "$IMAGE_TAG":latest
mkdir -p wheelhouse
docker cp mp_pip_package_container:/wheelhouse/. wheelhouse/
docker rm -f mp_pip_package_container

printf "\nBuild complete! Wheels are in the wheelhouse/ directory:\n"
ls -lh wheelhouse/

printf "\nTo install the wheel, run:\n"
printf "  pip install wheelhouse/*.whl\n"
