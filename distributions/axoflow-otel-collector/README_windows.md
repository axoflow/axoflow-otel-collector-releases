# Windows installation

## Installation steps

1. Download the proper artifact for your platform. (We provide MSI installers aswell as binary releases for amd64 and arm64 architectures.)

2. Run the installer.

The installer ships the following components:

  * Installs the application (by default) to `C:\Program Files\Axoflow\OpenTelemetry Collector\axoflow-otel-collector.exe`
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

Logs are buffered indefinitely in the default storage directory: `C:\ProgramData\Axoflow\OpenTelemetry Collector\storage`. This ensures no logs are lost during outages.

Add `otlp/axorouter` to the `exporters` section of the configuration file.

The default configuration supports the following formats.

### Event log

The default configuration collects from the following channels: `application`, `system`, `security`.

**NOTE: If you would like to include additonal channels you can use the following snippet and add it as a new receiver. (Don't forget to include the additonal receiver in the pipeline of your choice).**

```yaml
receivers:
  windowseventlog/<CHANNEL_NAME>:
    channel: <CHANNEL_NAME>
    raw: true
```

### DNS log

You can retrieve the DNS logfile path with the following PowerShell command:

```powershell
(Get-DnsServerDiagnostics).LogFilePath

C:\dns.log
```

Please note that you have to escape your backslashes in your path. (E.g., `C:\\dns.log`)

```yaml
receivers:
  filelog/windows_dns_debug_log:
    include: ['<ESCAPED_DNS_LOGFILE_PATH>']
    ...
```

### DHCP log

You can retrieve the DHCP log path with the following PowerShell command:

```powershell
(Get-DhcpServerAuditLog).Path

C:\dhcp
```

By default DHCP server logfiles start with either of these prefixes: `DhcpSrvLog` `DhcpV6SrvLog`.

You have to configure both DHCP filelog receivers (`filelog/windows_dhcp_server_v4_auditlog` and `filelog/windows_dhcp_server_v6_auditlog`)

```yaml
receivers:
  filelog/windows_dhcp_server_v4_auditlog:
    include: ['<ESCAPED_DHCP_SERVER_LOGS_PATH>\\DhcpSrvLog*']
    ...

  filelog/windows_dhcp_server_v6_auditlog:
    include: ['<ESCAPED_DHCPV6_SERVER_LOGS_PATH>\\DhcpV6SrvLog*']
    ...
```

## Support

If you have any questions, get in touch with us on [Discord](https://discord.gg/583Z4wjem2)!
