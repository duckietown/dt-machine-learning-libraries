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

# TO build torch vision I need pytroch first:
# download PyTorch
echo "Downloading PyTorch v${PYTORCH_VERSION}..."
PYTORCH_WHEEL_NAME="torch-${PYTORCH_VERSION}-cp38-cp38-linux_aarch64.whl"
WHEEL_URL="https://duckietown-public-storage.s3.amazonaws.com/assets/python/wheels/${PYTORCH_WHEEL_NAME}"
wget -q "${WHEEL_URL}" -O "/tmp/${PYTORCH_WHEEL_NAME}"
# install PyTorch
echo "Installing PyTorch v${PYTORCH_VERSION}..."
pip3 install "/tmp/${PYTORCH_WHEEL_NAME}"
rm "/tmp/${PYTORCH_WHEEL_NAME}"


export PILLOW_VERSION="Pillow<7"
export TORCH_CUDA_ARCH_LIST="5.3;6.2;7.2"

printenv && echo "torchvision version = $TORCHVISION_VERSION" && echo "pillow version = $PILLOW_VERSION" && echo "TORCH_CUDA_ARCH_LIST = $TORCH_CUDA_ARCH_LIST"

apt-get update && \
apt-get install -y --no-install-recommends \
        build-essential \
        libjpeg-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

cd "${SCRIPTPATH}/src"
mkdir dist/
python3 setup.py bdist_wheel
cp -R dist/* /out/