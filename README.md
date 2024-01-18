# ML Library Builder

## Description
Many popular machine-learning packages have C++ libraries associated with them.
Like with any compiled library, many options exist to modify their
functionality. This repository was originally intended to build libtorch for use
on Mac OSX platforms using ARM64 architectures (e.g. Apple Silicon M1). While
targeted primarily for users and developers of SmartSim, we hope that it will
be useful more broadly. Note that because of this, we are likely only going
to upgrade the backend versions as we need to and will likely not do a new
release for every version.

Future work includes building other variants of the libraries as needed or
including support for other backends like TensorFlow and ONNX.

## Requirements
To use this library, please ensure that the following requirements are fulfilled:

- Mac OSX (Intel or Apple Silicon)
- Xcode version >=12.2
- Make >=4.3
- Cmake >=3.24
- Python 3.10

Note: lower versions than those might also work

## Instructions
Briefly, the following should be sufficient to clone and build from this repository.

```
git clone --recursive https://github.com/CrayLabs/ml_lib_builder.git
cd ml_lib_builder
pip install -r pytorch/requirements.txt
make torch
```

This will result in a zipped tarfile containing all the shared libraries that
comprise libtorch.