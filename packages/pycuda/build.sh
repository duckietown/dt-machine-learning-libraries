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

wget https://pypi.io/packages/source/p/pycuda/pycuda-2021.1.tar.gz -O pycuda.tar.gz
tar -xf pycuda.tar.gz --one-top-level=pycuda-extracted --strip-components 1
# ensures numpy exists
pip3 install numpy
python3 configure.py --cuda-root=/usr/local/cuda

cd "${SCRIPTPATH}/src"
mkdir dist/
python3 setup.py bdist_wheel
cp -R dist/* /out/






