#!/bin/bash

mv "./distributions/axoflow-otel-collector/manifest.yaml.bak" "./distributions/axoflow-otel-collector/manifest.yaml"
rm -f "./distributions/axoflow-otel-collector/manifest.yaml.bak"
echo "Restored the original manifest.yaml file."
