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
IMAGE_REPO=${DOCKER_IMAGE_REPO:-axoflow/signer}
BASE_IMAGE=${DOCKER_BASE_IMAGE:-debian:stable-slim}
OSSLSIGNCODE_VERSION=${OSSLSIGNCODE_VERSION:-latest}
DOCKERFILE=${DOCKERFILE:-signer-image/Dockerfile}

# Generate image tag
if [[ $OSSLSIGNCODE_VERSION == "latest" ]]; then
    TAG="latest"
else
    TAG="$OSSLSIGNCODE_VERSION"
fi

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
    --build-arg OSSLSIGNCODE_VERSION="$OSSLSIGNCODE_VERSION" \
    --tag "$IMAGE_NAME" \
    .

#################################################
# Test the image
#################################################
echo "Testing the built image..."
docker run --rm "$IMAGE_NAME" --version

echo "Build completed successfully!"
echo "Image: $IMAGE_NAME"
