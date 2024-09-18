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


ifeq ($(ARCH_FILE),)
$(error Must specify ARCH_FILE)
else
include $(ARCH_FILE)
endif

INSTALL_DIR = $(PWD)/install
BUILD_DIR = $(PWD)/build

TORCH_ARCHIVE = $(INSTALL_DIR)/libtorch-$(PYTORCH_VERSION)-$(OS)-$(ARCHITECTURE)-$(STACK).tgz
TORCH_BUILD_DIR = $(BUILD_DIR)/libtorch
TORCH_INSTALL_DIR = $(INSTALL_DIR)/libtorch

TF_ARCHIVE = $(INSTALL_DIR)/libtensorflow-$(TF_VERSION)-$(OS)-$(ARCHITECTURE)-$(STACK).tgz
TF_INSTALL_DIR = $(INSTALL_DIR)/libtensorflow
# Note: TF uses its own build system; cannot specify a build directory

ONNXRT_ARCHIVE = $(INSTALL_DIR)/onnxruntime-$(ONNXRT_VERSION)-$(OS)-$(ARCHITECTURE)-$(STACK).tgz
ONNXRT_BUILD_DIR = $(BUILD_DIR)/onnxruntime
ONNXRT_INSTALL_DIR = $(INSTALL_DIR)/onnxruntime

.PHONY: help
help:
	@grep "^# help\:" Makefile | grep -v grep | sed 's/\# help\: //' | sed 's/\# help\://'

# help:
# help: ----Overview----
# help: This makefile can be used to builds ML backends for use on arm64. Generally
# help: all that needs to be done to accomplish this is
# help:
# help:    pip install -r pytorch/requirements.txt
# help:    make torch
# help:
# help: ----Meta targets----
# help: clean						-- Cleans all build and install directories
.PHONY: clean
clean: clean_torch clean_tensorflow clean_onnxruntime

# help: ----Build Targets----

## Torch section
$(TORCH_BUILD_DIR):
	mkdir -p $@

$(TORCH_ARCHIVE): $(TORCH_ARCHIVE_MODS) compile_torch
	cd $(INSTALL_DIR) && tar -czf $@ libtorch/

# help: build_torch					-- Builds libtorch
.PHONY: build_torch
build_torch: $(TORCH_ARCHIVE)

.PHONY: clean_torch
clean_torch:
	cd pytorch && git clean -fdx && git restore .
	cd pytorch/third_party/kineto && git restore .

.PHONY: compile_torch
compile_torch: $(TORCH_BUILD_DIR) $(PYTORCH_PREBUILD_TARGETS)
	cd $(TORCH_BUILD_DIR) && \
		cmake -GNinja -DCMAKE_INSTALL_PREFIX=$(TORCH_INSTALL_DIR) -DPYTHON_EXECUTABLE=$$(which python) \
		 	$(TORCH_CMAKE_OPTIONS) ../../pytorch && \
		ninja install

.PHONY: clean_tensorflow
clean_tensorflow:
	rm -rf $(TF_INSTALL_DIR)
	cd tensorflow && \
		bazel clean --expunge_async && \
		git restore . && \
		git reset --hard

.PHONY: clean_onnxruntime
clean_onnxruntime:
	rm -rf $(ONNXRT_INSTALL_DIR) $(ONNXRT_BUILD_DIR)
	cd onnxruntime && \
		git reset --hard && \
		git clean -fdx && \
		git restore .

## Tensorflow section
$(TF_INSTALL_DIR):
	mkdir -p $@

$(TF_ARCHIVE): $(TF_PREBUILD_TARGETS) $(TF_INSTALL_DIR)
	cd tensorflow && \
		bazel build $(TF_BAZEL_OPTS) //tensorflow/tools/lib_package:libtensorflow
	cp tensorflow/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz $(TF_INSTALL_DIR)
	cd $(TF_INSTALL_DIR) && tar -xzf libtensorflow.tar.gz && rm -f libtensorflow.tar.gz
	cd $(INSTALL_DIR) && tar -czf $@ libtensorflow

# help: build_tensorflow			-- Builds Tensorflow
.PHONY: build_tensorflow
build_tensorflow: $(TF_ARCHIVE)

## ONNX Runtime
compile_onnxruntime: $(ONNXRT_PREBUILD_TARGETS)
	cd onnxruntime && \
		git apply ../patches/onnxruntime/build.install.patch
	cd onnxruntime && python tools/ci_build/build.py \
		--config Release \
		--build_dir=$(ONNXRT_BUILD_DIR) \
		--compile_no_warning_as_error \
		--parallel \
		--skip_tests \
		--install_dir=$(ONNXRT_INSTALL_DIR) \
		--build_shared_lib \
		$(ONNXRT_OPTIONS)

$(ONNXRT_ARCHIVE): compile_onnxruntime
	cd $(ONNXRT_BUILD_DIR)/Release && make install
	cd $(ONNXRT_INSTALL_DIR) && mv include/onnxruntime/* include && rm -rf include/onnxruntime && mv lib64 lib
	cd $(INSTALL_DIR) && tar -czf $@ onnxruntime/

# help: build_onnxruntime			-- Builds ONNX Runtime
.PHONY: build_onnxruntime
build_onnxruntime: $(ONNXRT_ARCHIVE)
