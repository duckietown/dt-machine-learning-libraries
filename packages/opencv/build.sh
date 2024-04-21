#!/usr/bin/env bash

#
#   NOTE: This script is based on the instructions from the official website:
#       https://docs.cupy.dev/en/stable/install.html#installing-cupy-from-source
#


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
mkdir ./dist

# git dubious ownership
git config --global --add safe.directory ./src

# patch pyproject.toml according to issue: https://github.com/opencv/opencv-python/issues/835
sudo sed -i 's/numpy==1.22.2/numpy==1.26.4/g' ./pyproject.toml

# move setuptools to a higher version that supports Python 3.12
sudo sed -i 's/setuptools==59.2.0/setuptools==69.5.0/g' ./pyproject.toml

# configure build
export ENABLE_CONTRIB=0
export ENABLE_HEADLESS=1

# enable gstreamer and ffmpeg support
export CMAKE_ARGS="-DWITH_GSTREAMER=ON -DWITH_FFMPEG=ON"

# build
python3 -m pip wheel . --verbose --wheel-dir ./dist

# copy wheel out
cp -R ./dist/opencv* /out/
