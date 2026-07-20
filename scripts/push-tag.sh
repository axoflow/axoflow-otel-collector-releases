#!/bin/bash

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# This script creates and pushes the specified TAG to REMOTE,
# validating first that every manifest dist.version matches the tag.

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v yq &> /dev/null; then
    echo "This script requires 'yq'. Please install and try again."
    exit 1
fi

if [ -z "${TAG:-}" ]; then
    echo "TAG must be set (e.g. TAG=v0.156.0-axoflow.0)"
    exit 1
fi
if [[ ! "${TAG}" =~ ^v.* ]]; then
    echo "TAG must start with lowercase 'v' (e.g. v0.156.0-axoflow.0)"
    exit 1
fi

REMOTE="${REMOTE:-git@github.com:axoflow/axoflow-otel-collector-releases.git}"
VALIDATE="${VALIDATE:-true}"
VERSION="${TAG#v}"

if [ "${VALIDATE}" = "true" ]; then
    checked=0
    for dir in distributions/*/; do
        manifest="${dir}manifest.yaml"
        if [ -f "${manifest}" ]; then
            checked=$((checked + 1))
            dist_version=$(yq '.dist.version' "${manifest}")
            if [ "${dist_version}" != "${VERSION}" ]; then
                echo "Version mismatch in ${manifest}: dist.version is set to '${dist_version}', expected '${VERSION}'"
                echo "Bump the manifest version before tagging."
                echo "If this version mismatch is expected, please re-run with VALIDATE=false"
                exit 1
            fi
        fi
    done
    if [ "${checked}" -eq 0 ]; then
        echo "No manifest found to validate — refusing to tag."
        exit 1
    fi
fi

echo "Adding tag ${TAG}"
git tag -a "${TAG}" -s -m "Version ${TAG}"
echo "Pushing tag ${TAG}"
git push "${REMOTE}" "${TAG}"
