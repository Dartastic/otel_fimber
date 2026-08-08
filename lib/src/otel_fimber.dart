// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:fimber/fimber.dart' as fimber_lib;

import 'otel_fimber_suppression.dart';

/// Attribute keys for Fimber-specific log metadata that has no
/// upstream semantic-convention registry entry yet.
///
/// The exception attributes on records use the registry's
/// `exception.*` keys ([ExceptionAttributes]); this enum covers only
/// the Fimber tag. If the registry grows a matching convention,
/// these can `@Deprecated`-pivot.
enum FimberLogSemantics implements OTelSemantic {
  /// The Fimber tag for the log call — either the explicit `tag:`
  /// argument or Fimber's auto-derived caller tag.
  logTag('log.tag');

  const FimberLogSemantics(this.key);

  @override
  final String key;

  @override
  String toString() => key;
}

/// A `package:fimber` [LogTree] that mirrors every event into the
/// OpenTelemetry logs pipeline.
///
/// Plant the tree once at startup so every `Fimber.d/i/w/e/v/...`
/// call is reflected in your OTel backend:
///
/// ```dart
/// Fimber.plantTree(OTelFimberTree());
/// Fimber.i('user signed in');
/// ```
///
/// You can keep Fimber's own dev console tree planted alongside —
/// trees run independently:
///
/// ```dart
/// Fimber.plantTree(DebugTree());
/// Fimber.plantTree(OTelFimberTree());
/// ```
///
/// Each call becomes one OTel log record:
/// - `body` — the original message (with `tag:` prefix only when
///   `prependTag` is `true`).
/// - `severity_number` — mapped from the Fimber level letter
///   (`V`/`T` → TRACE, `D` → DEBUG, `I` → INFO, `W` → WARN,
///   `E` → ERROR, `F` → FATAL).
/// - `severity_text` — the original Fimber level string.
/// - attributes — [FimberLogSemantics.logTag] (when present), and the
///   registry's [ExceptionAttributes.exceptionType] /
///   [ExceptionAttributes.exceptionMessage] /
///   [ExceptionAttributes.exceptionStacktrace] when `ex` /
///   `stacktrace` are set.
///
/// Records inherit `trace_id` / `span_id` from `Context.current`, so
/// log calls inside a `Tracer.startActiveSpan` block are
/// auto-correlated with the surrounding span.
class OTelFimberTree extends fimber_lib.LogTree {
  /// Creates the tree.
  ///
  /// - [loggerProvider] — defaults to `OTel.loggerProvider()` at
  ///   first use.
  /// - [loggerName] — instrumentation scope name. Defaults to
  ///   `package.fimber`.
  /// - [levels] — Fimber level letters this tree handles. Defaults
  ///   to all six (`V`, `D`, `I`, `W`, `E`, `F`).
  /// - [includeStackTrace] — when `false`, the stack trace from `ex`
  ///   / `stacktrace` is not attached. Defaults to `true`.
  /// - [prependTag] — when `true`, prefix the body with the tag in
  ///   square brackets (matches Fimber's console output shape).
  ///   Defaults to `false`; the tag is always exported as a
  ///   `log.tag` attribute regardless.
  OTelFimberTree({
    LoggerProvider? loggerProvider,
    String loggerName = 'package.fimber',
    List<String>? levels,
    bool includeStackTrace = true,
    bool prependTag = false,
  })  : _provider = loggerProvider,
        _loggerName = loggerName,
        _levels = levels ?? const ['V', 'D', 'I', 'W', 'E', 'F'],
        _includeStackTrace = includeStackTrace,
        _prependTag = prependTag;

  final LoggerProvider? _provider;
  final String _loggerName;
  final List<String> _levels;
  final bool _includeStackTrace;
  final bool _prependTag;

  @override
  List<String> getLevels() => _levels;

  @override
  void log(
    String level,
    String message, {
    String? tag,
    dynamic ex,
    StackTrace? stacktrace,
  }) {
    if (fimberInstrumentationSuppressed()) return;
    final provider = _provider ?? OTel.loggerProvider();
    final logger = provider.getLogger(_loggerName);

    final attrs = <Attribute<Object>>[];
    if (tag != null && tag.isNotEmpty) {
      attrs.add(OTel.attributeString(FimberLogSemantics.logTag.key, tag));
    }
    if (ex != null) {
      attrs
        ..add(OTel.attributeString(
          ExceptionAttributes.exceptionType.key,
          ex.runtimeType.toString(),
        ))
        ..add(OTel.attributeString(
          ExceptionAttributes.exceptionMessage.key,
          ex.toString(),
        ));
    }
    if (_includeStackTrace && stacktrace != null) {
      attrs.add(OTel.attributeString(
        ExceptionAttributes.exceptionStacktrace.key,
        stacktrace.toString(),
      ));
    }

    final body = (_prependTag && tag != null && tag.isNotEmpty)
        ? '[$tag] $message'
        : message;

    logger.emit(
      timeStamp: DateTime.now(),
      severityNumber: _mapLevel(level),
      severityText: level,
      body: body,
      attributes: attrs.isEmpty ? null : OTel.attributes(attrs),
    );
  }
}

Severity _mapLevel(String level) {
  switch (level.toUpperCase()) {
    case 'V':
    case 'T':
      return Severity.TRACE;
    case 'D':
      return Severity.DEBUG;
    case 'I':
      return Severity.INFO;
    case 'W':
      return Severity.WARN;
    case 'E':
      return Severity.ERROR;
    case 'F':
      return Severity.FATAL;
    default:
      return Severity.INFO;
  }
}
