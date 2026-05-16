# otel_fimber

OpenTelemetry log bridge for
[`package:fimber`](https://pub.dev/packages/fimber).

Plant an `OTelFimberTree` alongside Fimber's debug tree and every
`Fimber.v/d/i/w/e/...` call is mirrored into the OpenTelemetry logs
pipeline. Records inherit `trace_id` / `span_id` from the active span,
so log calls inside a `Tracer.startActiveSpan` block are
auto-correlated.

## Install

```yaml
dependencies:
  fimber: ^0.7.0
  otel_fimber: ^0.1.0
```

## Use

```dart
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:fimber/fimber.dart';
import 'package:otel_fimber/otel_fimber.dart';

Future<void> main() async {
  await OTel.initialize(
    serviceName: 'my-app',
    endpoint: 'http://localhost:4317',
  );

  Fimber.plantTree(DebugTree());        // keep dev console output
  Fimber.plantTree(OTelFimberTree());   // mirror to OTel

  Fimber.i('user signed in');
  Fimber.e('boom', ex: StateError('out of stock'), stacktrace: StackTrace.current);
}
```

## Severity mapping

| Fimber level | OTel `severity_number` |
|--------------|------------------------|
| `V` / `T`    | `TRACE`                |
| `D`          | `DEBUG`                |
| `I`          | `INFO`                 |
| `W`          | `WARN`                 |
| `E`          | `ERROR`                |
| `F`          | `FATAL`                |

## Suppression

```dart
runWithoutFimberInstrumentation(() {
  Fimber.i('not exported to OTel');
});
```

## License

Apache 2.0 — copyright Mindful Software LLC.
