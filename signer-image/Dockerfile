#syntax=docker/dockerfile:1
#
# SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
# SPDX-FileContributor: Sebastian Thomschke
# SPDX-License-Identifier: Apache-2.0
# SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-osslsigncode

ARG BASE_IMAGE=debian:stable-slim

FROM ${BASE_IMAGE} AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG LC_ALL=C
ARG OSSLSIGNCODE_VERSION=latest

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    build-essential \
    libssl-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    autoconf \
    automake \
    libtool \
    python3-pkgconfig \
    cmake \
    faketime \
    python3 \
    && rm -rf /var/lib/apt/lists/*

RUN <<EOF
  if [ "$OSSLSIGNCODE_VERSION" = "latest" ]; then
    OSSLSIGNCODE_VERSION=$(curl -s https://api.github.com/repos/mtrojnar/osslsigncode/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  fi
  
  curl -fsS "https://codeload.github.com/mtrojnar/osslsigncode/tar.gz/refs/tags/$OSSLSIGNCODE_VERSION" | tar xvz
  mv osslsigncode-* osslsigncode
  cd osslsigncode
  mkdir build
  
  if [ -f CMakeLists.txt ]; then
    sed -i '/include(CMakeTest)/d' CMakeLists.txt
    cd build
    cmake -Denable-strict=ON -Denable-pedantic=ON ..
    cmake --build ./
  else
    ./bootstrap
    ./configure
    make
    mv osslsigncode build
    cd build
  fi
  
  strip osslsigncode
  ./osslsigncode --version
EOF

FROM ${BASE_IMAGE} AS final

ARG DEBIAN_FRONTEND=noninteractive
ARG LC_ALL=C

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    libssl3 \
    libcurl4 \
    netbase \
    wget \
    sudo \
    python3 \
    pkgconf \
    make \
    build-essential \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /osslsigncode/build/osslsigncode /usr/local/bin/osslsigncode

# Install EV code signing dependencies
RUN <<EOF
  wget https://github.com/GoogleCloudPlatform/kms-integrations/releases/download/pkcs11-v1.5/libkmsp11-1.5-linux-amd64.tar.gz
  tar -xzf libkmsp11-1.5-linux-amd64.tar.gz
  mkdir -p /usr/lib/x86_64-linux-gnu/pkcs11
  cp libkmsp11-1.5-linux-amd64/libkmsp11.so /usr/lib/x86_64-linux-gnu/pkcs11/libkmsp11.so

  wget https://github.com/OpenSC/libp11/releases/download/libp11-0.4.16/libp11-0.4.16.tar.gz
  tar -xzf libp11-0.4.16.tar.gz
  cd libp11-0.4.16
  ./configure && make && make install
  cd ..
  
  rm -rf libkmsp11-1.5-linux-amd64* libp11-0.4.16*
EOF

RUN mkdir /work && chmod 555 /usr/local/bin/osslsigncode

ENV PKCS11_MODULE_PATH=/usr/lib/x86_64-linux-gnu/pkcs11/libkmsp11.so

LABEL \
  org.opencontainers.image.title="osslsigncode" \
  org.opencontainers.image.description="Docker image for signing Windows binaries with Microsoft Authenticode using osslsigncode" \
  maintainer="Axoflow Inc."

WORKDIR /work

ENTRYPOINT ["/usr/local/bin/osslsigncode"]
