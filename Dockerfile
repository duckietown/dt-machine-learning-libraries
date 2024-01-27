# parameters
ARG PROJECT_NAME
ARG PROJECT_DESCRIPTION
ARG PROJECT_MAINTAINER
# pick an icon from: https://fontawesome.com/v4.7.0/icons/
ARG PROJECT_ICON="cube"
ARG PROJECT_FORMAT_VERSION

# ==================================================>
# ==> Do not change the code below this line
ARG ARCH
ARG DISTRO
ARG DOCKER_REGISTRY
ARG BASE_REPOSITORY
ARG BASE_ORGANIZATION=duckietown
ARG BASE_TAG=${DISTRO}-${ARCH}
ARG LAUNCHER=default

# define base image
FROM ${DOCKER_REGISTRY}/${BASE_ORGANIZATION}/${BASE_REPOSITORY}:${BASE_TAG} as base

# recall all arguments
ARG ARCH
ARG DISTRO
ARG DOCKER_REGISTRY
ARG PROJECT_NAME
ARG PROJECT_DESCRIPTION
ARG PROJECT_MAINTAINER
ARG PROJECT_ICON
ARG PROJECT_FORMAT_VERSION
ARG BASE_TAG
ARG BASE_REPOSITORY
ARG BASE_ORGANIZATION
ARG LAUNCHER
# - buildkit
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# check build arguments
RUN dt-args-check \
    "PROJECT_NAME" "${PROJECT_NAME}" \
    "PROJECT_DESCRIPTION" "${PROJECT_DESCRIPTION}" \
    "PROJECT_MAINTAINER" "${PROJECT_MAINTAINER}" \
    "PROJECT_ICON" "${PROJECT_ICON}" \
    "PROJECT_FORMAT_VERSION" "${PROJECT_FORMAT_VERSION}" \
    "ARCH" "${ARCH}" \
    "DISTRO" "${DISTRO}" \
    "DOCKER_REGISTRY" "${DOCKER_REGISTRY}" \
    "BASE_REPOSITORY" "${BASE_REPOSITORY}" \
    && dt-check-project-format "${PROJECT_FORMAT_VERSION}"

# define/create repository path
ARG PROJECT_PATH="${SOURCE_DIR}/${PROJECT_NAME}"
ARG PROJECT_LAUNCHERS_PATH="${LAUNCHERS_DIR}/${PROJECT_NAME}"
RUN mkdir -p "${PROJECT_PATH}" "${PROJECT_LAUNCHERS_PATH}"
WORKDIR "${PROJECT_PATH}"

# keep some arguments as environment variables
ENV DT_PROJECT_NAME="${PROJECT_NAME}" \
    DT_PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION}" \
    DT_PROJECT_MAINTAINER="${PROJECT_MAINTAINER}" \
    DT_PROJECT_ICON="${PROJECT_ICON}" \
    DT_PROJECT_PATH="${PROJECT_PATH}" \
    DT_PROJECT_LAUNCHERS_PATH="${PROJECT_LAUNCHERS_PATH}" \
    DT_LAUNCHER="${LAUNCHER}"

# jetpack environment
ENV JETPACK_VERSION 4.4.1

# nvidia environment
ENV CUDA_VERSION 10.2
ENV CUDNN_VERSION 8.0

# install apt dependencies
COPY ./dependencies-apt.txt "${PROJECT_PATH}/"
RUN dt-apt-install ${PROJECT_PATH}/dependencies-apt.txt

# install python3 dependencies
ARG PIP_INDEX_URL="https://pypi.org/simple"
ENV PIP_INDEX_URL=${PIP_INDEX_URL}
COPY ./dependencies-py3.* "${PROJECT_PATH}/"
RUN dt-pip3-install "${PROJECT_PATH}/dependencies-py3.*"


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
ENV TORCHVISION_VERSION v0.8.1
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

# trt_pose
RUN mkdir -p packages/trt_pose && \
    cd packages/trt_pose && \
    git clone https://github.com/NVIDIA-AI-IOT/torch2trt ./src

# clean environment
RUN pip3 uninstall -y dataclasses

# copy the source code
COPY ./packages "${PROJECT_PATH}/packages"

# install launcher scripts
COPY ./launchers/. "${PROJECT_LAUNCHERS_PATH}/"
RUN dt-install-launchers "${PROJECT_LAUNCHERS_PATH}"

# install scripts
COPY ./assets/entrypoint.d "${PROJECT_PATH}/assets/entrypoint.d"
COPY ./assets/environment.d "${PROJECT_PATH}/assets/environment.d"

# define default command
CMD ["bash", "-c", "dt-launcher-${DT_LAUNCHER}"]

# store module metadata
LABEL \
    # module info
    org.duckietown.label.project.name="${PROJECT_NAME}" \
    org.duckietown.label.project.description="${PROJECT_DESCRIPTION}" \
    org.duckietown.label.project.maintainer="${PROJECT_MAINTAINER}" \
    org.duckietown.label.project.icon="${PROJECT_ICON}" \
    org.duckietown.label.project.path="${PROJECT_PATH}" \
    org.duckietown.label.project.launchers.path="${PROJECT_LAUNCHERS_PATH}" \
    # format
    org.duckietown.label.format.version="${PROJECT_FORMAT_VERSION}" \
    # platform info
    org.duckietown.label.platform.os="${TARGETOS}" \
    org.duckietown.label.platform.architecture="${TARGETARCH}" \
    org.duckietown.label.platform.variant="${TARGETVARIANT}" \
    # code info
    org.duckietown.label.code.distro="${DISTRO}" \
    org.duckietown.label.code.launcher="${LAUNCHER}" \
    org.duckietown.label.code.python.registry="${PIP_INDEX_URL}" \
    # base info
    org.duckietown.label.base.organization="${BASE_ORGANIZATION}" \
    org.duckietown.label.base.repository="${BASE_REPOSITORY}" \
    org.duckietown.label.base.tag="${BASE_TAG}"
# <== Do not change the code above this line
# <==================================================

# configure environment for CUDA
ENV PATH /usr/local/cuda-${CUDA_VERSION}/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:${LD_LIBRARY_PATH}
ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs:${LIBRARY_PATH}
ENV CUDA_TOOLKIT_ROOT_DIR /usr/local/cuda-${CUDA_VERSION}/
ENV NVIDIA_REQUIRE_CUDA "cuda>=${CUDA_VERSION} brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441"
