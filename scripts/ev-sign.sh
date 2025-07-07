#!/bin/bash
set -e

MSI_FILES=$(find "distributions/axoflow-otel-collector/dist" -name "*.msi" -type f)
if [ -z "$MSI_FILES" ]; then
    echo "No MSI files found to sign"
    exit 0
fi

echo "Found MSI files to sign:"
echo "$MSI_FILES"

mkdir -p /tmp/signed-msi

echo "$MSI_FILES" | while IFS= read -r msi_file; do
    echo "Signing: $msi_file"

    abs_msi_file=$(realpath "$msi_file")
    filename=$(basename "$msi_file")
    signed_filename="signed_${filename}"

    log_file=$(mktemp)
    if ! docker run --rm \
        -v "$abs_msi_file:/work/$filename" \
        -v "/tmp/signed-msi:/work/signed" \
        -v "${GOOGLE_GHA_CREDS_PATH}:/creds.json:ro" \
        -v "${KMS_PKCS11_CONFIG}:${KMS_PKCS11_CONFIG}:ro" \
        -v "${CERTIFICATE_CRT_PATH}:${CERTIFICATE_CRT_PATH}:ro" \
        -e GOOGLE_APPLICATION_CREDENTIALS="/creds.json" \
        -e KMS_PKCS11_CONFIG="${KMS_PKCS11_CONFIG}" \
        -e CERTIFICATE_CRT_PATH="${CERTIFICATE_CRT_PATH}" \
        -e GCP_KEY_NAME="${GCP_KEY_NAME}" \
        axoflow/signer:latest \
        sign \
            -provider /usr/lib/x86_64-linux-gnu/ossl-modules/pkcs11prov.so \
            -pkcs11module /usr/lib/x86_64-linux-gnu/pkcs11/libkmsp11.so \
            -key "pkcs11:object=${GCP_KEY_NAME}" \
            -certs "${CERTIFICATE_CRT_PATH}" \
            -n "Axoflow OpenTelemetry Collector" \
            -i "https://axoflow.com" \
            -h sha256 \
            -t "http://timestamp.sectigo.com" \
            -in "/work/$filename" \
            -out "/work/signed/$signed_filename" > "$log_file" 2>&1; then
        echo "ERROR: Docker signing command failed for $filename"
        echo "Error details:"
        cat "$log_file"
        rm -f "$log_file"
        exit 1
    fi
    rm -f "$log_file"
    
    if [ -f "/tmp/signed-msi/$signed_filename" ]; then
        echo "Successfully signed: $filename"

        mv "/tmp/signed-msi/$signed_filename" "$msi_file"
        echo "Replaced original with signed version: $msi_file"
    else
        echo "ERROR: Failed to create signed file for $filename"
        exit 1
    fi
done

echo "All MSI files have been successfully signed and replaced"
