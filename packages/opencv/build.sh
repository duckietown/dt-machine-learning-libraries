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

sudo sh -c "echo '/usr/local/cuda/lib64' >> /etc/ld.so.conf.d/nvidia-tegra.conf"
sudo ldconfig

# remove old versions or previous builds
cd ~ 
sudo rm -rf opencv*
# download version 4.5.0
wget -O opencv.zip https://github.com/opencv/opencv/archive/4.5.0.zip 
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.5.0.zip 
# unpack
unzip opencv.zip 
unzip opencv_contrib.zip 
# some administration to make live easier later on
mv opencv-4.5.0 opencv
mv opencv_contrib-4.5.0 opencv_contrib
# clean up the zip files
rm opencv.zip
rm opencv_contrib.zip

# set install dir
cd ~/opencv
mkdir build
cd build
sudo mkdir /opt/opencv
sudo ls /opt/opencv

# run cmake
cmake -D CMAKE_BUILD_TYPE=RELEASE \
-D CMAKE_INSTALL_PREFIX=/opt/opencv \
-D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
-D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
-D WITH_OPENCL=OFF \
-D WITH_CUDA=ON \
-D CUDA_ARCH_BIN=5.3 \
-D CUDA_ARCH_PTX="" \
-D WITH_CUDNN=ON \
-D WITH_CUBLAS=ON \
-D ENABLE_FAST_MATH=ON \
-D CUDA_FAST_MATH=ON \
-D OPENCV_DNN_CUDA=ON \
-D ENABLE_NEON=ON \
-D WITH_QT=OFF \
-D WITH_OPENMP=ON \
-D BUILD_TIFF=ON \
-D WITH_FFMPEG=ON \
-D WITH_GSTREAMER=ON \
-D WITH_TBB=ON \
-D BUILD_TBB=ON \
-D BUILD_TESTS=OFF \
-D WITH_EIGEN=ON \
-D WITH_V4L=ON \
-D WITH_LIBV4L=ON \
-D OPENCV_ENABLE_NONFREE=ON \
-D INSTALL_C_EXAMPLES=OFF \
-D INSTALL_PYTHON_EXAMPLES=OFF \
-D BUILD_NEW_PYTHON_SUPPORT=ON \
-D BUILD_opencv_python3=TRUE \
-D OPENCV_GENERATE_PKGCONFIG=ON \
-D BUILD_EXAMPLES=OFF \
-D BUILD_SHARED_LIBS=OFF ..


make -j 8

sudo rm -r /usr/include/opencv4/opencv2
sudo ls /opt/opencv

sudo make install
sudo ldconfig

# cleaning (frees 300 MB)
# make clean

echo "Testing OpenCV python CUDA support"

echo "Copying the files from the install directory to the output volume"
sudo ls /opt/opencv
sudo cp -r /opt/opencv/* ${OUTPUT_DIR}/
sudo cp -r lib/python3.8/dist-packages/cv2/python-3.8 ${OUTPUT_DIR}/lib/python3.8/dist-packages/cv2

echo "Congratulations!"
echo "You've successfully installed OpenCV 4.5.0 on your Jetson Nano"
