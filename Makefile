PYTORCH_VERSION=v2.1.2
OSX_ARCHITECTURE=arm64

.PHONY: help
help:
	@grep "^# help\:" Makefile | grep -v grep | sed 's/\# help\: //' | sed 's/\# help\://'

# help: ----Description----
# help: Builds ML backends for use on Apple Silicon.
# help:
# help: ----Build Targets----
# help: torch						-- Builds libtorch
TORCH_TARGET = libtorch-macos-arm64-$(PYTORCH_VERSION).tgz
TORCH_BUILD = $(PWD)/build/torch
TORCH_INSTALL = $(PWD)/install/torch
.PHONY: torch
torch: $(TORCH_TARGET)

.PHONY: checkout_torch
checkout_torch:
	cd pytorch && git checkout $(PYTORCH_VERSION) && git submodule sync --recursive


$(TORCH_BUILD):
	mkdir -p $@

$(TORCH_INSTALL):
	mkdir -p $@

.PHONY: build_torch
build_torch: $(TORCH_BUILD) $(TORCH_INSTALL) checkout_torch
	cd $< && \
		cmake -DCMAKE_INSTALL_PREFIX=$(TORCH_INSTALL) -DCMAKE_OSX_ARCHITECTURE=$(OSX_ARCHITECTURE) ../../pytorch && \
		make install -j 6

$(TORCH_TARGET): build_torch
	cd install && tar -czf ../$@ torch

.PHONY: clean_torch
clean_torch:
	rm -rf $(TORCH_BUILD) $(TORCH_TARGET)