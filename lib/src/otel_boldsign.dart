// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_boldsign_suppression.dart';

const _tracerName = 'dartastic_otel_libs_boldsign';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class BoldsignResult {
  /// Creates a result.
  const BoldsignResult({
    this.itemCount,
    this.totalRecords,
    this.documentId,
    this.status,
    this.brandId,
    this.signerCount,
    this.signedCount,
    this.embedded,
    this.envelopeKind,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// `totalRecords` paging field.
  final int? totalRecords;

  /// `documentId`.
  final String? documentId;

  /// `Draft` / `Sent` / `Completed` / `Declined` / `Revoked` /
  /// `Expired` / `WaitingForMe`.
  final String? status;

  /// Brand id used (BoldSign customers can run multiple brands).
  final String? brandId;

  /// Total signers.
  final int? signerCount;

  /// Count of signers who signed.
  final int? signedCount;

  /// True for embedded signing flows.
  final bool? embedded;

  /// `document` / `template` / `bulk_send`.
  final String? envelopeKind;

  /// `Boldsign-Request-Id` (when present).
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class BoldsignCallResult<T> {
  /// Creates a call result.
  const BoldsignCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final BoldsignResult? result;
}

/// Wraps a BoldSign API call in a CLIENT span. [operation] is one of
/// `document.list`, `document.get`, `document.send`,
/// `document.send_with_template`, `document.revoke`, `document.delete`,
/// `document.download`, `document.embedded_send`,
/// `document.embedded_sign_url`, `template.list`,
/// `template.create_embedded`, `brand.list`, `brand.create`,
/// `contact.list`, `bulk_send.list`, `bulk_send.create`,
/// `webhook.list`, `webhook.create`, `oauth.token`.
Future<T> tracedBoldsign<T>({
  required String operation,
  required Future<BoldsignCallResult<T>> Function() invoke,
}) async {
  if (boldsignInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'boldsign',
    'rpc.method': operation,
    'boldsign.operation': operation,
  };

  final span = _tracer().startSpan(
    'boldsign $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTelAPI.attributeInt(
          'boldsign.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.totalRecords != null) {
        extras.add(OTelAPI.attributeInt(
          'boldsign.total_records',
          r.result!.totalRecords!,
        ));
      }
      if (r.result!.documentId != null) {
        extras.add(OTelAPI.attributeString(
          'boldsign.document.id',
          r.result!.documentId!,
        ));
      }
      if (r.result!.status != null) {
        extras.add(OTelAPI.attributeString(
          'boldsign.document.status',
          r.result!.status!,
        ));
        if (r.result!.status == 'Declined' ||
            r.result!.status == 'Revoked' ||
            r.result!.status == 'Expired') {
          span.setStatus(
            SpanStatusCode.Error,
            'BoldSign ${r.result!.status}',
          );
        }
      }
      if (r.result!.brandId != null) {
        extras.add(OTelAPI.attributeString(
          'boldsign.brand.id',
          r.result!.brandId!,
        ));
      }
      if (r.result!.signerCount != null) {
        extras.add(OTelAPI.attributeInt(
          'boldsign.signer_count',
          r.result!.signerCount!,
        ));
      }
      if (r.result!.signedCount != null) {
        extras.add(OTelAPI.attributeInt(
          'boldsign.signed_count',
          r.result!.signedCount!,
        ));
      }
      if (r.result!.embedded != null) {
        extras.add(OTelAPI.attributeBool(
          'boldsign.embedded',
          r.result!.embedded!,
        ));
      }
      if (r.result!.envelopeKind != null) {
        extras.add(OTelAPI.attributeString(
          'boldsign.envelope.kind',
          r.result!.envelopeKind!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'boldsign.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'BoldSign HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
