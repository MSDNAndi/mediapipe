# Building MediaPipe Python Wheels

This document describes how to build MediaPipe Python wheels locally using Docker.

## Overview

MediaPipe provides Docker-based build systems for creating manylinux-compatible Python wheels. The wheels are built using:

- **manylinux_2_28_x86_64**: For x86_64 Linux systems (most desktop/server Linux)
- **manylinux2014_aarch64**: For ARM64 systems (Raspberry Pi, etc.)

## Quick Start

To build wheels locally using the provided script:

```bash
# Build for x86_64 with Python 3.12 (default)
./build_wheels.sh

# Build for x86_64 with Python 3.11
./build_wheels.sh 3.11

# Build for x86_64 with Python 3.9
./build_wheels.sh 3.9 x86_64

# Build for ARM64 (Raspberry Pi) with Python 3.12
./build_wheels.sh 3.12 aarch64
```

The wheels will be placed in the `wheelhouse/` directory.

### Supported Python Versions

- Python 3.9
- Python 3.10
- Python 3.11
- Python 3.12 (default)
- Python 3.13

### Supported Platforms

- **x86_64** (default) - Standard Linux desktop/server
- **aarch64** - ARM64 systems like Raspberry Pi

## Manual Build Process

If you prefer more control over the build process or want to customize it:

### Building for x86_64

```bash
# Build the Docker image for Python 3.12
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

For different Python versions, change the `--build-arg` parameter:
- Python 3.9: `PYTHON_BIN=/opt/python/cp39-cp39/bin/python3.9`
- Python 3.10: `PYTHON_BIN=/opt/python/cp310-cp310/bin/python3.10`
- Python 3.11: `PYTHON_BIN=/opt/python/cp311-cp311/bin/python3.11`
- Python 3.13: `PYTHON_BIN=/opt/python/cp313-cp313/bin/python3.13`

### Building for ARM64 (Raspberry Pi)

```bash
# Set up QEMU for cross-compilation (only needed if building on x86_64)
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Build the Docker image (Python 3.12 is hardcoded in this Dockerfile)
docker build \
  -f Dockerfile.manylinux2014_aarch64rp4 \
  -t mp_manylinux_aarch64rp4:latest \
  .

# Extract the wheel
docker create -ti --name mp_pip_package_container mp_manylinux_aarch64rp4:latest
docker cp mp_pip_package_container:/wheelhouse/. wheelhouse/
docker rm -f mp_pip_package_container
```

**Note:** The ARM64 Dockerfile currently only builds for Python 3.12. To build for other Python versions, you'll need to modify the Dockerfile.

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

- Docker (with BuildKit support for x86_64 builds)
- For ARM builds on x86_64: QEMU user-mode emulation
- At least 10GB of free disk space
- 8GB+ RAM recommended
- Build time: 30-60 minutes for x86_64, 2-4 hours for ARM64

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

### Where to Store Built Wheels

Built wheels are placed in the `wheelhouse/` directory (which is in `.gitignore`). You can:

1. **Use them locally**: Install directly from the wheelhouse directory
2. **Share them**: Copy to a shared location, upload to a private repository, or distribute as needed
3. **Upload to PyPI**: If you have appropriate credentials and permissions:
   ```bash
   pip install twine
   twine upload wheelhouse/*.whl
   ```

## Contributing

If you encounter issues or have suggestions for improving the wheel build process, please open an issue or pull request on GitHub.

## License

Copyright 2025 The MediaPipe Authors. Licensed under the Apache License 2.0.
