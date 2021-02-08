#!/bin/bash

# Install tensorflow involves 2 step:
# 1. get bazel compiled
# 2. get tensorflow compiled

OUTPUT_DIR=/out
SCRIPTPATH="$(
    cd "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"

# check volume
mountpoint -q "${OUTPUT_DIR}"
if [ $? -ne 0 ]; then
  echo "ERROR: The path '${OUTPUT_DIR}' is not a VOLUME. The resulting artefacts would be lost.
  Mount an external directory to it and retry."
  exit 1
fi

set -ex
cd "${SCRIPTPATH}/src"
# Build Bazel:
cd bazel
export EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk --python_path=/usr/bin/python3" 
ln -sf /usr/bin/python3 /usr/bin/python # This is mandatory as there is an upstream bug in bazel requiring linking "python" to python3
./compile.sh
cp /usr/local/bin/bazel /out/

# Configure Tensorflow
cd ../tensorflow
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 7 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 7 \ 
    && update-alternatives --config gcc \
    && update-alternatives --config g++

export PYTHON_BIN_PATH="/usr/bin/python3"
bazel build --config=cuda //tensorflow/tools/pip_package:build_pip_package
./bazel-bin/tensorflow/tools/pip_package/build_pip_package /out/