# Axoflow Signer

A Docker image for signing Windows binaries with Microsoft Authenticode using [osslsigncode](https://github.com/mtrojnar/osslsigncode), including support for EV (Extended Validation) code signing with hardware security modules.

## Overview

This Docker image provides a containerized environment for code signing Windows executables, DLLs, and other PE files using osslsigncode. It includes additional dependencies for EV code signing with PKCS#11 tokens and cloud-based HSMs like Google Cloud KMS.

## Usage

### Basic Code Signing

```bash
# Sign a Windows executable with a PFX certificate
docker run --rm -v $(pwd):/work axoflow/signer:latest \
    sign -pkcs12 /work/certificate.pfx -pass "password" \
    -in /work/unsigned.exe -out /work/signed.exe
```

### EV Code Signing with PKCS#11

```bash
# Sign with a hardware token or HSM
docker run --rm -v $(pwd):/work axoflow/signer:latest \
    sign -pkcs11module /usr/lib/x86_64-linux-gnu/pkcs11/libkmsp11.so \
    -pkcs11cert "pkcs11:token=MyToken;object=MyCert" \
    -in /work/unsigned.exe -out /work/signed.exe
```

### Google Cloud KMS

```bash
# Sign using Google Cloud KMS (requires proper authentication)
docker run --rm \
    -v $(pwd):/work \
    -v ~/.config/gcloud:/root/.config/gcloud:ro \
    -e GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json \
    axoflow/signer:latest \
    sign -pkcs11module /usr/lib/x86_64-linux-gnu/pkcs11/libkmsp11.so \
    -pkcs11cert "pkcs11:token=projects/PROJECT/locations/LOCATION/keyRings/RING/cryptoKeys/KEY/cryptoKeyVersions/1;object=cert" \
    -in /work/unsigned.exe -out /work/signed.exe
```

### Verification

```bash
# Verify a signed executable
docker run --rm -v $(pwd):/work axoflow/signer:latest \
    verify /work/signed.exe
```

## Building

### Build Commands

```bash
# Build with latest osslsigncode version
./build.sh

# Build with specific version
OSSLSIGNCODE_VERSION=2.8 ./build.sh

# Build with custom image name
DOCKER_IMAGE_REPO=mycompany/osslsigncode ./build.sh
```

### Build Arguments

- `BASE_IMAGE`: Base Docker image (default: `debian:stable-slim`)
- `OSSLSIGNCODE_VERSION`: osslsigncode version to build (default: `latest`)

## Environment Variables

- `PKCS11_MODULE_PATH`: Path to PKCS#11 module (default: `/usr/lib/x86_64-linux-gnu/pkcs11/libkmsp11.so`)

## Included Components

- **osslsigncode**: Core code signing tool
- **libkmsp11**: Google Cloud KMS PKCS#11 module
- **libp11**: OpenSSL PKCS#11 engine
- **OpenSSL**: Cryptographic library

## License and Source

This project is based on the original work by [Vegard IT GmbH](https://vegardit.com) and is available under the Apache License 2.0.

- **Original Source**: <https://github.com/vegardit/docker-osslsigncode>
- **License**: Apache License 2.0
- **Copyright**: © Vegard IT GmbH
- **Contributor**: Sebastian Thomschke

### SPDX License Information

```license
SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
SPDX-FileContributor: Sebastian Thomschke
SPDX-License-Identifier: Apache-2.0
SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-osslsigncode
```

## Support

For issues related to osslsigncode itself, please refer to the [osslsigncode project](https://github.com/mtrojnar/osslsigncode).

For issues with the original Docker implementation, please check the [upstream repository](https://github.com/vegardit/docker-osslsigncode).
