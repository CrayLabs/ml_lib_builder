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
$(warning Must specify ARCH_FILE)
else
include $(ARCH_FILE)
endif

TORCH_TARGET = libtorch-$(OS)-$(ARCHITECTURE)-$(PYTORCH_VERSION).zip
TORCH_BUILD = $(PWD)/build/libtorch
TORCH_INSTALL = $(PWD)/install/libtorch

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
clean: clean_torch

# help:
# help: ----Build Targets----
# help: torch						-- Builds libtorch
# help:
.PHONY: torch
torch: $(TORCH_TARGET)

# Checkout a specific version of Torch and update all of the torch submodules
.PHONY: checkout_torch
checkout_torch:
	cd pytorch && git checkout v$(PYTORCH_VERSION) && \
		git submodule foreach --recursive git reset --hard && \
		git submodule update --init --recursive

$(TORCH_BUILD) $(TORCH_INSTALL):
	mkdir -p $@

.PHONY: build_torch
build_torch: $(TORCH_BUILD) $(TORCH_INSTALL) $(PYTORCH_ROCM_PREBUILD_TARGETS)
	cd $< && \
		cmake -GNinja -DCMAKE_INSTALL_PREFIX=$(TORCH_INSTALL) $(TORCH_CMAKE_OPTIONS) ../../pytorch && \
		ninja

$(TORCH_TARGET): build_torch
	cd install && zip -r ../$@ libtorch

.PHONY: clean_torch
clean_torch:
	rm -rf $(TORCH_BUILD) $(TORCH_TARGET) $(TORCH_INSTALL)
	cd pytorch && git clean -fdx && git restore .
	cd pytorch/third_party/kineto && git restore .

