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
# Usage: ./build_wheels.sh [PYTHON_VERSION] [PLATFORM]
#   PYTHON_VERSION: 3.9, 3.10, 3.11, 3.12 (default), or 3.13
#   PLATFORM: x86_64 (default), aarch64

set -e

PYTHON_VERSION=${1:-3.12}
PLATFORM=${2:-x86_64}

# Map Python version to identifiers
case $PYTHON_VERSION in
  3.9)
    PYTHON_IDENTIFIER="cp39-cp39"
    ;;
  3.10)
    PYTHON_IDENTIFIER="cp310-cp310"
    ;;
  3.11)
    PYTHON_IDENTIFIER="cp311-cp311"
    ;;
  3.12)
    PYTHON_IDENTIFIER="cp312-cp312"
    ;;
  3.13)
    PYTHON_IDENTIFIER="cp313-cp313"
    ;;
  *)
    printf "Unknown Python version: %s\n" "$PYTHON_VERSION"
    printf "Supported versions: 3.9, 3.10, 3.11, 3.12, 3.13\n"
    exit 1
    ;;
esac

printf "Building MediaPipe wheel for %s with Python %s\n" "$PLATFORM" "$PYTHON_VERSION"
printf "==================================================\n"

if [ "$PLATFORM" == "x86_64" ]; then
  DOCKERFILE="Dockerfile.manylinux_2_28_x86_64"
  IMAGE_TAG="mp_manylinux_${PYTHON_IDENTIFIER}"

  printf "Building Docker image...\n"
  DOCKER_BUILDKIT=1 docker build \
    -f "$DOCKERFILE" \
    -t "$IMAGE_TAG":latest \
    --build-arg PYTHON_BIN="/opt/python/${PYTHON_IDENTIFIER}/bin/python${PYTHON_VERSION}" \
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
