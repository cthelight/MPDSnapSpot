IMAGE_NAME_NO_VER?="cthelight/mpdsnapspot"
TAG?=$(shell git describe --tags --always 2>/dev/null || echo dev)
IMAGE_NAME:=$(IMAGE_NAME_NO_VER):$(TAG)
# Platforms for multi-arch builds (override as needed)
PLATFORMS?="linux/amd64,linux/arm64/v8,linux/arm/v7"

.PHONY: all build build_tag multiarch_build_tag push build_alpine build_alpine_tag multiarch_build_tag_alpine librespot-lock clean

# Build for the host platform and load it into the local docker daemon.
all: build

build:
	docker buildx build --load -t $(IMAGE_NAME_NO_VER):latest .

build_tag:
	@docker buildx build --load -t $(IMAGE_NAME) .

# Multi-arch images cannot be loaded into a local docker daemon, so this
# builds all platforms and pushes the result to the registry.
multiarch_build_tag:
	@echo -n "Push $(IMAGE_NAME) for $(PLATFORMS)? [y/N] " && read ans && if ! [ $${ans:-'N'} = 'y' ]; then 1>&2 echo "Aborting..."; exit 1; fi
	docker buildx build --platform $(PLATFORMS) --tag $(IMAGE_NAME) --push .

# ---------------------------------------------------------------------------
# Alpine (musl) variant, see Dockerfile.alpine for the rationale.
# ---------------------------------------------------------------------------
build_alpine:
	docker buildx build --load -t $(IMAGE_NAME_NO_VER):latest -f Dockerfile.alpine .

build_alpine_tag:
	@docker buildx build --load -t $(IMAGE_NAME) -f Dockerfile.alpine .

multiarch_build_tag_alpine:
	@echo -n "Push $(IMAGE_NAME) for $(PLATFORMS)? [y/N] " && read ans && if ! [ $${ans:-'N'} = 'y' ]; then 1>&2 echo "Aborting..."; exit 1; fi
	docker buildx build --platform $(PLATFORMS) --tag $(IMAGE_NAME) --push -f Dockerfile.alpine .

# Push a single-platform (host architecture) image.
push:
	@echo -n "Push $(IMAGE_NAME)? [y/N] " && read ans && if ! [ $${ans:-'N'} = 'y' ]; then 1>&2 echo "Aborting..."; exit 1; fi
	docker buildx build --tag $(IMAGE_NAME) --push .

# Regenerate the pinned librespot Cargo.lock after bumping LIBRESPOT_VERSION:
#   make librespot-lock LIBRESPOT_VERSION=0.9.0
# The build installs librespot with --locked against this file, so the
# dependency tree (and the build) stays reproducible and immune to upstream
# registry changes.
librespot-lock:
	./tools/regen-librespot-lock.sh

clean:
	docker rmi $(IMAGE_NAME) 2>/dev/null || true
