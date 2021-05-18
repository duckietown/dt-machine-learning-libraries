# parameters
ARG REPO_NAME="dt-machine-learning-libraries"
ARG DESCRIPTION="Sandbox used to build machine learning libraries"
ARG MAINTAINER="Andrea F. Daniele (afdaniele@ttic.edu)"
# pick an icon from: https://fontawesome.com/v4.7.0/icons/
ARG ICON="cube"

# ==================================================>
# ==> Do not change the code below this line
ARG ARCH=arm32v7
ARG DISTRO=daffy
ARG BASE_TAG=${DISTRO}-${ARCH}
ARG BASE_IMAGE=dt-commons
ARG LAUNCHER=default

# define base image
FROM duckietown/${BASE_IMAGE}:${BASE_TAG} as BASE

# recall all arguments
ARG ARCH
ARG DISTRO
ARG REPO_NAME
ARG DESCRIPTION
ARG MAINTAINER
ARG ICON
ARG BASE_TAG
ARG BASE_IMAGE
ARG LAUNCHER

# check build arguments
RUN dt-build-env-check "${REPO_NAME}" "${MAINTAINER}" "${DESCRIPTION}"

# define/create repository path
ARG REPO_PATH="${SOURCE_DIR}/${REPO_NAME}"
ARG LAUNCH_PATH="${LAUNCH_DIR}/${REPO_NAME}"
RUN mkdir -p "${REPO_PATH}"
RUN mkdir -p "${LAUNCH_PATH}"
WORKDIR "${REPO_PATH}"

# keep some arguments as environment variables
ENV DT_MODULE_TYPE "${REPO_NAME}"
ENV DT_MODULE_DESCRIPTION "${DESCRIPTION}"
ENV DT_MODULE_ICON "${ICON}"
ENV DT_MAINTAINER "${MAINTAINER}"
ENV DT_REPO_PATH "${REPO_PATH}"
ENV DT_LAUNCH_PATH "${LAUNCH_PATH}"
ENV DT_LAUNCHER "${LAUNCHER}"

# generic environment
ENV LANG C.UTF-8

# jetpack environment
ENV JETPACK_VERSION 4.4.1

# nvidia environment
ENV CUDA_VERSION 10.2
ENV CUDNN_VERSION 8.0

# install apt dependencies
COPY ./dependencies-apt.txt "${REPO_PATH}/"
RUN dt-apt-install ${REPO_PATH}/dependencies-apt.txt

# install python3 dependencies
COPY ./dependencies-py3.txt "${REPO_PATH}/"
RUN pip3 install --use-feature=2020-resolver -r ${REPO_PATH}/dependencies-py3.txt

# Mute the annoying warning about detach HEAD

RUN git config --global advice.detachedHead false

# clone libraries
# - pyTorch
ENV PYTORCH_RELEASE 1.7
ENV PYTORCH_VERSION 1.7.0
RUN mkdir -p packages/pytorch && \
    cd packages/pytorch && \
    git clone --recursive --branch "v$PYTORCH_VERSION" http://github.com/pytorch/pytorch ./src && \
    cd src && \
    wget https://gist.githubusercontent.com/dusty-nv/ce51796085178e1f38e3c6a1663a93a1/raw/9d7261584a7482e7cc0fcb08a4a232c6d023f812/pytorch-${PYTORCH_RELEASE}-jetpack-${JETPACK_VERSION}.patch && \
    git apply pytorch-${PYTORCH_RELEASE}-jetpack-${JETPACK_VERSION}.patch && \
    rm pytorch-${PYTORCH_RELEASE}-jetpack-${JETPACK_VERSION}.patch
RUN pip3 install -r packages/pytorch/src/requirements.txt

# - CuPy
ENV CUPY_VERSION 8.0.0
RUN mkdir -p packages/cupy && \
    cd packages/cupy && \
    git clone --recursive --branch "v$CUPY_VERSION" http://github.com/cupy/cupy ./src

# - torchvision
ENV TORCHVISION_VERSION v0.8.2
RUN mkdir -p packages/torchvision && \
    cd packages/torchvision && \
    git clone --recursive --branch ${TORCHVISION_VERSION} https://github.com/pytorch/vision ./src

# - pycuda
ENV PYCUDA_VERSION 2021.1
RUN mkdir -p packages/pycuda && \
    cd packages/pycuda && \
    git clone --recursive --branch "v$PYCUDA_VERSION" https://github.com/inducer/pycuda ./src

# - tensorflow
# bazel builder:
ENV BAZEL_VERSION 3.1.0
RUN mkdir -p packages/tensorflow && \
    cd packages/tensorflow && \
    git clone --recursive --branch "$BAZEL_VERSION" https://github.com/bazelbuild/bazel ./src/bazel


# tensorflow builder:
ENV TENSORFLOW_VERSION 2.3.2 
RUN mkdir -p packages/tensorflow && \
    cd packages/tensorflow && \
    git clone -b daffy-2.3.2-arm64v8 https://github.com/duckietown/tensorflow ./src/tensorflow

# clean environment
RUN pip3 uninstall -y dataclasses

# copy the source code
COPY ./packages "${REPO_PATH}/packages"

# install launcher scripts
COPY ./launchers/. "${LAUNCH_PATH}/"
COPY ./launchers/default.sh "${LAUNCH_PATH}/"
RUN dt-install-launchers "${LAUNCH_PATH}"

# define default command
CMD ["bash", "-c", "dt-launcher-${DT_LAUNCHER}"]

# store module metadata
LABEL org.duckietown.label.module.type="${REPO_NAME}" \
    org.duckietown.label.module.description="${DESCRIPTION}" \
    org.duckietown.label.module.icon="${ICON}" \
    org.duckietown.label.architecture="${ARCH}" \
    org.duckietown.label.code.location="${REPO_PATH}" \
    org.duckietown.label.code.version.distro="${DISTRO}" \
    org.duckietown.label.base.image="${BASE_IMAGE}" \
    org.duckietown.label.base.tag="${BASE_TAG}" \
    org.duckietown.label.maintainer="${MAINTAINER}"
# <== Do not change the code above this line
# <==================================================

# configure environment for CUDA
ENV PATH /usr/local/cuda-${CUDA_VERSION}/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:${LD_LIBRARY_PATH}
ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs:${LIBRARY_PATH}
ENV CUDA_TOOLKIT_ROOT_DIR /usr/local/cuda-${CUDA_VERSION}/
ENV NVIDIA_REQUIRE_CUDA "cuda>=${CUDA_VERSION} brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441"
