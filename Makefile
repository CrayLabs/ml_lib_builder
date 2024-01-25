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

PYTORCH_VERSION=v2.0.1
OSX_ARCHITECTURE=arm64

TORCH_TARGET = libtorch-macos-arm64-$(PYTORCH_VERSION).tgz
TORCH_BUILD = $(PWD)/build/libtorch
TORCH_INSTALL = $(PWD)/install/libtorch

TORCH_CMAKE_OPTIONS =
TORCH_CMAKE_OPTIONS += -DCMAKE_OSX_ARCHITECTURES=$(OSX_ARCHITECTURE)
TORCH_CMAKE_OPTIONS += -DUSE_MKL=OFF -DUSE_MKLDNN=OFF -DUSE_ITT=OFF
TORCH_CMAKE_OPTIONS += -DUSE_QNNPACK=OFF -DUSE_KINETO=OFF

.PHONY: clean
clean: clean_torch

.PHONY: help
help:
	@grep "^# help\:" Makefile | grep -v grep | sed 's/\# help\: //' | sed 's/\# help\://'

# help: ----Description----
# help: Builds ML backends for use on arm64
# help:
# help: ----Build Targets----
# help: torch						-- Builds libtorch

.PHONY: torch
torch: $(TORCH_TARGET)

.PHONY: checkout_torch
checkout_torch:
	cd pytorch && git checkout $(PYTORCH_VERSION) && \
		git submodule foreach --recursive git reset --hard && \
		git submodule update --init --recursive

$(TORCH_BUILD):
	mkdir -p $@

$(TORCH_INSTALL):
	mkdir -p $@

.PHONY: build_torch
build_torch: $(TORCH_BUILD) $(TORCH_INSTALL) checkout_torch
	cd $< && \
		cmake -DCMAKE_INSTALL_PREFIX=$(TORCH_INSTALL) $(TORCH_CMAKE_OPTIONS) ../../pytorch && \
		make install -j 4

$(TORCH_TARGET): build_torch
	cd install && tar -czf ../$@ libtorch

.PHONY: clean_torch
clean_torch:
	rm -rf $(TORCH_BUILD) $(TORCH_TARGET)
