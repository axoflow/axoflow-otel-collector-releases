FROM alpine:3.23@sha256:865b95f46d98cf867a156fe4a135ad3fe50d2056aa3f25ed31662dff6da4eb62 as certs
RUN apk --no-cache --update add ca-certificates

FROM scratch

ARG USER_UID=10001
ARG USER_GID=10001
USER ${USER_UID}:${USER_GID}

COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --chmod=755 axoflow-otel-collector /axoflow-otel-collector
COPY linux_config.yaml /etc/axoflow-otel-collector/config.yaml
ENTRYPOINT ["/axoflow-otel-collector"]
CMD ["--config", "/etc/axoflow-otel-collector/config.yaml"]
EXPOSE 4317 4318 55679
