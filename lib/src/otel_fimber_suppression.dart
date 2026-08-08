// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #otel_fimber_suppress;

/// Whether Fimber→OTel mirroring is suppressed in the current [Zone].
///
/// `OTelFimberTree.log` checks this and drops the record when `true`.
bool fimberInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

/// Runs [body] with Fimber→OTel mirroring suppressed.
///
/// Use around code whose `Fimber.*` calls must not reach the OTel
/// logs pipeline (e.g. inside exporters, to avoid feedback loops).
T runWithoutFimberInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

/// Async variant of [runWithoutFimberInstrumentation]; the
/// suppression zone spans the whole returned future.
Future<T> runWithoutFimberInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
