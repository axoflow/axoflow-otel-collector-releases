# escape=`
ARG WIN_VERSION=2019
FROM mcr.microsoft.com/windows/nanoserver:ltsc${WIN_VERSION}

COPY axoflow-otel-collector.exe ./axoflow-otel-collector.exe
COPY windows_config.yaml ./windows_config.yaml

ENTRYPOINT ["axoflow-otel-collector.exe"]
CMD ["--config", "windows_config.yaml"]
EXPOSE 4317 4318 55679
