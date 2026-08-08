// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

// Plant an OTel LogTree beside Fimber's console tree: every
// `Fimber.*` call is mirrored into the OpenTelemetry logs pipeline
// and auto-correlated with the active span.
//
// Run with an OTLP endpoint available (defaults to
// http://localhost:4318) or swap in your own exporter/processor.
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:fimber/fimber.dart';
import 'package:otel_fimber/otel_fimber.dart';

Future<void> main() async {
  await OTel.initialize(serviceName: 'otel-fimber-example');

  // Keep Fimber's own console output AND mirror into OTel.
  Fimber.plantTree(DebugTree());
  Fimber.plantTree(OTelFimberTree());

  Fimber.i('app started'); // -> OTel log record, severity INFO

  // Logs inside an active span inherit its trace_id/span_id.
  final tracer = OTel.tracer();
  final span = tracer.startSpan('sign-in');
  try {
    Fimber.i('user signed in'); // correlated with the sign-in span
    throw StateError('bad credentials cache');
  } catch (e, st) {
    // exception.type / exception.message / exception.stacktrace
    // attributes are attached from ex + stacktrace.
    Fimber.e('sign-in cleanup failed', ex: e, stacktrace: st);
  } finally {
    span.end();
  }

  // Suppress mirroring for a scope (e.g. inside exporters).
  runWithoutFimberInstrumentation(() {
    Fimber.d('not mirrored to OTel');
  });

  await OTel.shutdown();
}
