
# BSD 2-Clause License
#
# Copyright (c) 2024, Hewlett Packard Enterprise
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

OS = linux
ARCHITECTURE = x64
ROCM_VERSION = 6.1.2
STACK=rocm-$(ROCM_VERSION)

# pyTorch options
PYTORCH_VERSION = 2.4.0
TORCH_CMAKE_OPTIONS = -DBUILD_PYTHON=OFF
TORCH_CMAKE_OPTIONS += -DUSE_ROCM=ON -DUSE_RCCL=ON -DROCM_SOURCE_DIR=${ROCM_PATH}
TORCH_CMAKE_OPTIONS += -DUSE_NCCL=OFF -DUSE_CUDA=OFF -DUSE_STATIC_MKL=ON
PYTORCH_PREBUILD_TARGETS = pytorch_rocm_checkout pytorch_rocm_prebuild


# Tensorflow options
TF_VERSION = 2.15
TF_TAG = r$(TF_VERSION)-rocm-enhanced
TF_REMOTE = https://github.com/ROCm/tensorflow-upstream.git
TF_PREBUILD_TARGETS = tf_rocm_checkout tf_rocm_prebuild
TF_BAZEL_OPTS = --config=opt --verbose_failures

ONNXRT_VERSION = 1.17.3
ONNXRT_OPTIONS = --use_rocm --rocm_home $(ROCM_PATH)
ONNXRT_PREBUILD_TARGETS = onnxrt_checkout
# No prebuild steps for ONNX

# From PyTorch for ROCm instructions
# https://github.com/pytorch/pytorch/blob/v2.3.1/README.md?plain=1#L241-L245
# For at ROCm 5.5.0 and later, also need to patch one of the ATen files
pytorch_rocm_checkout:
	cd pytorch && \
		git checkout v${PYTORCH_VERSION} && \
		git submodule update --init --recursive && \
		git reset --hard

pytorch_rocm_prebuild:
	cd pytorch; python tools/amd_build/build_amd.py
	sed -i 's/attr.memoryType/attr.type/g' pytorch/aten/src/ATen/hip/detail/HIPHooks.cpp
	sed -i 's,/opt/rocm,${ROCM_PATH},g' pytorch/third_party/kineto/libkineto/CMakeLists.txt
	sed -i 's,\.,\\.,g' pytorch/cmake/public/LoadHIP.cmake

# (1) Patch .bazelrc to avoid hard-coded paths to Clang
# (2) Run the bazel configure script
tf_rocm_prebuild:
	cd tensorflow; \
		git restore .bazelrc
	# 	git apply ../patches/tensorflow/bazelrc.rocm.patch
	cd tensorflow; \
		USE_DEFAULT_PYTHON_LIB_PATH=1 \
		PYTHON_BIN_PATH=$$(which python) \
		TF_NEED_CLANG=0 \
		TF_NEED_ROCM=1 \
		TF_NEED_CUDA=0 \
		CC_OPT_FLAGS="-Wno-sign-compare -B/usr/bin" \
		TF_SET_ANDROID_WORKSPACE=0 \
		python configure.py

tf_rocm_checkout:
	cd tensorflow; \
		git fetch $(TF_REMOTE) $(TF_TAG) && \
		git checkout FETCH_HEAD

onnxrt_checkout:
	cd onnxruntime && \
		git checkout v$(ONNXRT_VERSION) && \
		git reset --hard && \
		git clean -xdf && \
		git submodule update --init --recursive
