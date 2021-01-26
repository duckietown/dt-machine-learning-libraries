# dt-machine-learning-libraries
Docker environment you can use to build CUDA-compatible Machine Learning tools and libraries for NVidia Jetson Nano boards.


## Environment

The environment in which the libraries are built is the combination of host and container
libraries. In particular,

### Host Libraries:

| Library   | Version       |
| --------- | ------------- |
| CUDA      | 10.2(.89)     |
| CuDNN     | 8.0(.0.180)   |

### Container Libraries:

Check the lists `dependencies-apt.txt` and `dependencies-py3.txt` for the container libraries.


## How to use it

The Docker image (i.e., environment) can be built on any machine (i.e., any architecture).
The libraries build when the image is run, and this can only happen on a machine with `arm64v8` 
architecture and with the proper version of CUDA and CuDNN installed.

NOTE: This Docker image DOES NOT have CUDA/CuDNN installed in it. CUDA and CuDNN are mounted
by the `nvidia` runtime for Docker.

### Build the image

Build the environment image using the command:

```shell
dts devel build
```

### Run the image (build the library)

Build a library using the command:

```shell
dts devel run -L <library_name> -- -v $(pwd)/dist:/out
```

where, `library_name` is one of those available in the 
`/launchers` directory of this repository.
The final python wheel will be available in the directory
`/dist` of this repository once the building has completed.

### Where to run

As of January 2020
