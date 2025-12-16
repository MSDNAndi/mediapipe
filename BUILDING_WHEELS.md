# Building MediaPipe Python Wheels

This document describes how to build prebuilt MediaPipe Python wheels for distribution.

## Overview

MediaPipe provides Docker-based build systems for creating manylinux-compatible Python wheels that can be distributed on PyPI or used locally. The wheels are built using:

- **manylinux_2_28_x86_64**: For x86_64 Linux systems (most desktop/server Linux)
- **manylinux2014_aarch64**: For ARM64 systems (Raspberry Pi, etc.)

## Quick Start

### Automated Build with GitHub Actions

The easiest way to build wheels is using the GitHub Actions workflow:

1. **For tagged releases** (automatic):
   ```bash
   git tag v0.10.30
   git push origin v0.10.30
   ```
   This will automatically build wheels for all supported Python versions (3.9-3.13) and create a GitHub release with the wheels attached.

2. **For manual builds** (via workflow dispatch):
   - Go to the "Actions" tab in GitHub
   - Select "Build Python Wheels"
   - Click "Run workflow"
   - Choose the Python version and platform(s) to build
   - Download the artifacts after the build completes

### Local Build with Docker

To build wheels locally:

```bash
# Build for x86_64 with Python 3.12 (default)
./build_wheels.sh

# Build for x86_64 with Python 3.11
./build_wheels.sh x86_64 cp311-cp311

# Build for ARM64 (Raspberry Pi)
./build_wheels.sh aarch64
```

The wheels will be placed in the `wheelhouse/` directory.

#### Supported Python Versions

- `cp39-cp39` - Python 3.9
- `cp310-cp310` - Python 3.10
- `cp311-cp311` - Python 3.11
- `cp312-cp312` - Python 3.12
- `cp313-cp313` - Python 3.13

## Manual Build Process

If you want more control over the build process:

### Building for x86_64

```bash
# Build the Docker image
DOCKER_BUILDKIT=1 docker build \
  -f Dockerfile.manylinux_2_28_x86_64 \
  -t mp_manylinux:latest \
  --build-arg PYTHON_BIN=/opt/python/cp312-cp312/bin/python3.12 \
  .

# Extract the wheel
docker create -ti --name mp_pip_package_container mp_manylinux:latest
docker cp mp_pip_package_container:/wheelhouse/. wheelhouse/
docker rm -f mp_pip_package_container
```

### Building for ARM64 (Raspberry Pi)

```bash
# Set up QEMU for cross-compilation (if building on x86_64)
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Build the Docker image
docker build \
  -f Dockerfile.manylinux2014_aarch64rp4 \
  -t mp_manylinux_aarch64rp4:latest \
  .

# Extract the wheel
docker create -ti --name mp_pip_package_container mp_manylinux_aarch64rp4:latest
docker cp mp_pip_package_container:/wheelhouse/. wheelhouse/
docker rm -f mp_pip_package_container
```

## Installation

Once you have built the wheel, you can install it with:

```bash
pip install wheelhouse/mediapipe-*.whl
```

## What's Included

The wheels include:

- MediaPipe Python API (`mediapipe` package)
- MediaPipe Tasks for Vision, Audio, and Text
- Pre-built native library (`libmediapipe.so`)
- Statically linked OpenCV (core and imgproc modules only)
- All necessary dependencies

## Requirements

### For Local Builds

- Docker (with BuildKit support for x86_64 builds)
- For ARM builds on x86_64: QEMU user-mode emulation
- At least 10GB of free disk space
- 8GB+ RAM recommended

### For GitHub Actions Builds

- Push access to the repository
- GitHub Actions enabled

## Troubleshooting

### Docker Build Fails

If the Docker build fails:

1. Ensure you have enough disk space (at least 10GB free)
2. Try cleaning Docker: `docker system prune -a`
3. For ARM builds, ensure QEMU is properly set up

### Wheel Installation Fails

If the wheel fails to install:

1. Ensure you're using a compatible Linux distribution
2. Check Python version compatibility
3. Try installing in a fresh virtual environment

### Missing Dependencies

The wheels should include all necessary dependencies. If you encounter import errors:

1. Ensure you're on a compatible Linux distribution (glibc 2.28+ for x86_64)
2. Check that all system dependencies are met (they should be minimal)

## Advanced Topics

### Customizing the Build

You can customize the build by modifying:

- `Dockerfile.manylinux_2_28_x86_64` - x86_64 build configuration
- `Dockerfile.manylinux2014_aarch64rp4` - ARM64 build configuration
- `mediapipe_python_build.diff` - Patches applied during build
- `setup.py` - Python package configuration

### Building for Different OpenCV Configurations

By default, the wheels build with minimal OpenCV (core and imgproc modules only). To include more modules, modify the Dockerfile's OpenCV build configuration.

### Version Management

The version number is automatically extracted from `mediapipe/version.bzl` during the Docker build. To change the version:

1. Edit `mediapipe/version.bzl`
2. Rebuild the wheel

## Contributing

If you encounter issues or have suggestions for improving the wheel build process, please open an issue or pull request on GitHub.

## License

Copyright 2025 The MediaPipe Authors. Licensed under the Apache License 2.0.
