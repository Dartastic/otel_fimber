# Changelog

## [0.2.0-wip]

### Changed

- Semantic conventions updated to the current OTel registry: exception
  attributes are emitted via the registry's `ExceptionAttributes` enums
  (`exception.type` / `exception.message` / `exception.stacktrace`) —
  no raw string attribute keys anywhere.
- Dependency floors raised to `dartastic_opentelemetry ^1.1.0-beta.12` and
  `dartastic_opentelemetry_api ^1.0.0-rc.1`. The previous floors declared
  compatibility with API versions that predate the semconv enums this
  package uses and could not actually resolve-and-compile.
- `repository` URL corrected to the canonical `Dartastic` org casing so
  pub.dev repository verification succeeds.

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
