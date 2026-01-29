#!/bin/sh

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

if command -v systemctl >/dev/null 2>&1; then
    if [ -d /run/systemd/system ]; then
        systemctl daemon-reload
    fi
    systemctl enable axoflow-otel-collector.service
    if [ -f /etc/axoflow-otel-collector/config.yaml ]; then
        if [ -d /run/systemd/system ]; then
            systemctl restart axoflow-otel-collector.service
        fi
    fi
fi
