# Changelog

## [0.1.0-beta.1-wip]

### Added

- `OTelFimberTree` — a `package:fimber` `LogTree` that mirrors every
  event into the OpenTelemetry logs pipeline.
- Severity mapping (V/T → TRACE, D → DEBUG, I → INFO, W → WARN,
  E → ERROR, F → FATAL).
- `log.tag` attribute on every record; `exception.type` /
  `exception.message` / `exception.stacktrace` when `ex` /
  `stacktrace` are set.
- Configurable handled levels via `levels:`; defaults to all six.
- Optional `prependTag: true` to match Fimber's `[tag] message`
  console shape (the tag is always exported as an attribute regardless).
- Zone-scoped suppression via `runWithoutFimberInstrumentation()`.
