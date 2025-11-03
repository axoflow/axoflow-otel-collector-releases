#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
# SPDX-FileContributor: Sebastian Thomschke
# SPDX-License-Identifier: Apache-2.0
# SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-osslsigncode

set -euo pipefail

#################################################
# Configuration
#################################################
TAG="${1:-latest}"

IMAGE_REPO=${DOCKER_IMAGE_REPO:-axoflow/signer}
BASE_IMAGE=${DOCKER_BASE_IMAGE:-debian}
BASE_IMAGE_VERSION=${DOCKER_BASE_IMAGE_VERSION:-stable-slim@sha256:a771c85b2287eae7ce8fe0a4c2637d575c5d991555ae680c187c5572153648d9}
DOCKERFILE=${DOCKERFILE:-signer-image/Dockerfile}

IMAGE_NAME="$IMAGE_REPO:$TAG"

echo "Building Docker image: $IMAGE_NAME"
echo "Base image: $BASE_IMAGE"
echo "osslsigncode version: $OSSLSIGNCODE_VERSION"

#################################################
# Build the image
#################################################
docker build \
    --file "$DOCKERFILE" \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    --build-arg BASE_IMAGE_VERSION="$BASE_IMAGE_VERSION" \
    --tag "$IMAGE_NAME" \
    .

#################################################
# Test the image
#################################################
echo "Testing the built image..."
docker run --rm "$IMAGE_NAME" --version

echo "Build completed successfully!"
echo "Image: $IMAGE_NAME"
