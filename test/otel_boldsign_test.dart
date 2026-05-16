// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_boldsign/otel_boldsign.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_boldsign-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('document.send records brand + signers + embedded', () async {
    await tracedBoldsign<String>(
      operation: 'document.send',
      invoke: () async => const BoldsignCallResult(
        value: 'ok',
        result: BoldsignResult(
          documentId: 'd-1',
          status: 'Sent',
          brandId: 'br-1',
          signerCount: 2,
          signedCount: 0,
          embedded: false,
          envelopeKind: 'document',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('boldsign document.send')!);
    expect(a['boldsign.brand.id'], 'br-1');
    expect(a['boldsign.signer_count'], 2);
    expect(a['boldsign.embedded'], false);
  });

  test('Revoked sets span error', () async {
    await tracedBoldsign<String>(
      operation: 'document.revoke',
      invoke: () async => const BoldsignCallResult(
        value: 'ok',
        result: BoldsignResult(status: 'Revoked'),
      ),
    );
    expect(
      spans.findSpanByName('boldsign document.revoke')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutBoldsignInstrumentationAsync(() async {
      await tracedBoldsign<String>(
        operation: 'document.list',
        invoke: () async => const BoldsignCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('boldsign '), isEmpty);
  });
}
