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

set -eux

echo "Installing OpenCV 4.5.0 on your Jetson Nano"

# switch to gcc7
sudo update-alternatives \
    --install /usr/bin/gcc gcc /usr/bin/gcc-7 100 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-7 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-7

# Test if opencv custom build is already installed running a test script
cd /home/root
g++ test_opencv.cpp -o test_opencv `pkg-config --cflags --libs opencv4`
./test_opencv
