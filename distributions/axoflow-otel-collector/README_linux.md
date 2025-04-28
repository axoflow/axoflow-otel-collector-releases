# Linux installation

## Installation steps

1. Download the proper artifact for your platform. (We provide RPM and DEB packages aswell as binary releases for amd64 and arm64 architectures.)

2. Run the installer.

The installer ships the following components:

  * Installs the application (by default) to `/usr/bin/axoflow-otel-collector`
  * A default configuration that should be edited before use.

## Configuration

Provide the OTLP connector's address and port. (E.g., `10.0.2.2:4317`)

```yaml
exporters:
  otlp/axorouter:
    endpoint: 10.0.2.2:4317
```

In production environments [TLS settings](https://github.com/open-telemetry/opentelemetry-collector/blob/main/config/configtls/README.md) should be set accordingly.

To ensure log reliability, the following retry and queue settings are enabled by default:

```yaml
exporters:
  otlp/axorouter:
    retry_on_failure:
      enabled: true
      max_elapsed_time: 0
    sending_queue:
      enabled: true
      storage: file_storage
```

Logs are buffered indefinitely in the default storage directory: `/etc/axoflow-otel-collector/storage`. This ensures no logs are lost during outages.

Add `otlp/axorouter` to the `exporters` section of the configuration file.

**NOTE: Don't forget to add the same endpoint in the telemetry section too!**

You can use the [Telemetry controller](https://axoflow.com/reinvent-kubernetes-logging-with-telemetry-controller/) to simplify the creation of collector configuration in Kubernetes environments.

You can read more about the OpenTelemetry Collector configuration in it's official [documentation](https://opentelemetry.io/docs/collector/configuration/).

## Support

If you have any questions, get in touch with us on [Discord](https://discord.gg/583Z4wjem2)!
