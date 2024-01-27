export PATH=/usr/local/cuda-${CUDA_VERSION}/bin:${PATH}
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu/:/usr/local/cuda-${CUDA_VERSION}/lib64:/usr/local/cuda-${CUDA_VERSION}/extras/CUPTI/lib64:${LD_LIBRARY_PATH}
export LIBRARY_PATH=/usr/local/cuda-${CUDA_VERSION}/lib64/stubs:${LIBRARY_PATH}
export CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-${CUDA_VERSION}/
export NVIDIA_REQUIRE_CUDA="cuda>=${CUDA_VERSION} brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441"
