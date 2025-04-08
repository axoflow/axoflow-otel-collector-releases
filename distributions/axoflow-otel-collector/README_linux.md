# Linux installation

## Installation steps

1. Download the proper artifact for your platform. (We provide RPM and DEB packages aswell as binary releases for amd64 and arm64 architectures.)

2. Run the installer.

The installer ships the following components:

  * Installs the application (by default) to `/usr/bin/axoflow-otel-collector`
  * A default configuration that must be edited before use.

## Configuration

Provide the OTLP connector's address and port. (E.g., `10.0.2.2:4317`)

```yaml
exporters:
  otlp/axorouter:
    endpoint: 10.0.2.2:4317
    tls:
      insecure: true
```

**NOTE: Don't forget to add the same endpoint in the telemetry section too!**

You can use the [Telemetry controller](https://axoflow.com/reinvent-kubernetes-logging-with-telemetry-controller/) to simplify the creation of collector configuration in Kubernetes environments.

You can read more about the OpenTelemetry Collector configuration in it's official [documentation](https://opentelemetry.io/docs/collector/configuration/).

## Support

If you have any questions, get in touch with us on [Discord](https://discord.gg/583Z4wjem2)!
