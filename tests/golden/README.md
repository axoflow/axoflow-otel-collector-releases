# Golden file test

End-to-end regression test for the log pipeline: the collector container reads
`data/input.log` via the filelog receiver, zeroes timestamps (transform
processor, see `config.yaml`), and writes OTLP JSON with the file exporter.
`run.sh` canonicalizes the emitted log records with `jq` (sorted keys, one
record per line — independent of batching) and diffs them against
`data/expected.jsonl`.

Upstream's `cmd/golden` utility is not used: it only implements the OTLP
metrics service, and this distribution's pipeline is logs.

## Run

```shell
make golden-test IMG=ghcr.io/axoflow/axoflow-otel-collector/axoflow-otel-collector:<version>
```

## Refresh the expected output

Only needed if the filelog receiver's output shape changes intentionally:

```shell
make golden-record IMG=ghcr.io/axoflow/axoflow-otel-collector/axoflow-otel-collector:<version>
```

Commit the updated `data/expected.jsonl` and review the diff.
