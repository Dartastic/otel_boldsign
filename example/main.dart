// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_boldsign/otel_boldsign.dart';

/// Traces BoldSign calls with OpenTelemetry.
///
/// `otel_boldsign` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each BoldSign call in
/// [tracedBoldsign]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'boldsign-example');

  // Wraps a BoldSign API call in a CLIENT span.
  final boldsignId = await tracedBoldsign<String>(
    operation: 'template.create_embedded',
    invoke: () async {
      // Make the BoldSign call here, then report what it returned.
      const id = 'boldsign_8f3a2c';
      return const BoldsignCallResult(
          value: id,
          result: BoldsignResult(
              itemCount: 3,
              totalRecords: 1,
              documentId: 'document_8f3a2c',
              status: 'Draft',
              brandId: 'brand_8f3a2c',
              signerCount: 3,
              signedCount: 3,
              embedded: true,
              envelopeKind: 'document',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedBoldsign template.create_embedded returned $boldsignId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutBoldsignInstrumentationAsync.
  await runWithoutBoldsignInstrumentationAsync(
    () => tracedBoldsign<String>(
      operation: 'template.create_embedded',
      invoke: () async {
        const id = 'boldsign_8f3a2c';
        return const BoldsignCallResult(
            value: id,
            result: BoldsignResult(
                itemCount: 3,
                totalRecords: 1,
                documentId: 'document_8f3a2c',
                status: 'Draft',
                brandId: 'brand_8f3a2c',
                signerCount: 3,
                signedCount: 3,
                embedded: true,
                envelopeKind: 'document',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
