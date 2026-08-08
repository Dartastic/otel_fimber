// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:fimber/fimber.dart';
import 'package:otel_fimber/otel_fimber.dart';
import 'package:test/test.dart';

class _MemoryLogExporter implements LogRecordExporter {
  final List<LogRecord> records = [];
  bool _shutdown = false;

  @override
  Future<ExportResult> export(List<LogRecord> r) async {
    if (_shutdown) return ExportResult.failure;
    records.addAll(r);
    return ExportResult.success;
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

void main() {
  group('OTelFimberTree', () {
    late _MemoryLogExporter exporter;
    late OTelFimberTree tree;

    setUp(() async {
      await OTel.reset();
      exporter = _MemoryLogExporter();
      await OTel.initialize(
        serviceName: 'otel_fimber-test',
        detectPlatformResources: false,
        logRecordProcessor: SimpleLogRecordProcessor(exporter),
      );
      Fimber.clearAll();
      tree = OTelFimberTree();
      Fimber.plantTree(tree);
    });

    tearDown(() async {
      Fimber.unplantTree(tree);
      await OTel.shutdown();
      await OTel.reset();
    });

    test('mirrors Fimber.i() into the OTel pipeline', () async {
      Fimber.i('user signed in');
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, hasLength(1));
      final rec = exporter.records.first;
      expect(rec.body.toString(), contains('user signed in'));
      expect(rec.severityNumber, Severity.INFO);
    });

    test('maps Fimber levels: V/D/I/W/E', () async {
      Fimber.v('v');
      Fimber.d('d');
      Fimber.i('i');
      Fimber.w('w');
      Fimber.e('e');
      await OTel.loggerProvider().forceFlush();
      final sevs = exporter.records.map((r) => r.severityNumber).toSet();
      expect(
        sevs,
        containsAll(<Severity>[
          Severity.TRACE,
          Severity.DEBUG,
          Severity.INFO,
          Severity.WARN,
          Severity.ERROR,
        ]),
      );
    });

    test('records exception attributes on Fimber.e with ex+stack', () async {
      try {
        throw StateError('boom');
      } catch (e, st) {
        Fimber.e('caught it', ex: e, stacktrace: st);
      }
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, isNotEmpty);
      final rec = exporter.records.last;
      final attrMap = {
        for (final a in rec.attributes!.toList()) a.key: a.value,
      };
      expect(attrMap[ExceptionAttributes.exceptionType.key], 'StateError');
      expect(
        attrMap[ExceptionAttributes.exceptionMessage.key],
        contains('boom'),
      );
      expect(
        attrMap[ExceptionAttributes.exceptionStacktrace.key],
        isNotNull,
      );
    });

    test('respects zone-scoped suppression', () async {
      runWithoutFimberInstrumentation(() {
        Fimber.i('should not appear');
      });
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, isEmpty);
    });
  });
}
