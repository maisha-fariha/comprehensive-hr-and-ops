import 'package:flutter/foundation.dart';

enum OutboxStatus {
  pending,
  sending,
  failed,
  conflict;

  static OutboxStatus parse(String? raw) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return OutboxStatus.pending;
  }

  bool get needsAttention =>
      this == OutboxStatus.failed || this == OutboxStatus.conflict;
}

/// A file captured offline that must be uploaded before its owning write.
@immutable
class OutboxAttachment {
  final String id;
  final String localPath;
  final String field;
  final String filename;
  final String? mime;
  final String uploadPath;
  final Map<String, dynamic>? uploadQuery;
  final Map<String, String> fields;

  /// Set once the file reached the server so retries never upload it twice.
  final String? uploadedUrl;

  const OutboxAttachment({
    required this.id,
    required this.localPath,
    required this.field,
    required this.filename,
    required this.uploadPath,
    this.mime,
    this.uploadQuery,
    this.fields = const {},
    this.uploadedUrl,
  });

  OutboxAttachment withUploadedUrl(String url) => OutboxAttachment(
        id: id,
        localPath: localPath,
        field: field,
        filename: filename,
        mime: mime,
        uploadPath: uploadPath,
        uploadQuery: uploadQuery,
        fields: fields,
        uploadedUrl: url,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'localPath': localPath,
        'field': field,
        'filename': filename,
        'mime': mime,
        'uploadPath': uploadPath,
        'uploadQuery': uploadQuery,
        'fields': fields,
        'uploadedUrl': uploadedUrl,
      };

  factory OutboxAttachment.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    return OutboxAttachment(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      field: (json['field'] as String?) ?? 'file',
      filename: (json['filename'] as String?) ?? 'file',
      mime: json['mime'] as String?,
      uploadPath: json['uploadPath'] as String,
      uploadQuery: (json['uploadQuery'] as Map?)?.cast<String, dynamic>(),
      fields: rawFields is Map
          ? rawFields.map((k, v) => MapEntry('$k', '$v'))
          : const {},
      uploadedUrl: json['uploadedUrl'] as String?,
    );
  }
}

/// One write recorded on this device, waiting to reach the server.
@immutable
class OutboxItem {
  final String id;
  final int seq;
  final String userId;
  final String tenant;
  final String method;
  final String path;
  final Map<String, dynamic>? query;
  final dynamic jsonBody;
  final List<OutboxAttachment> attachments;
  final String idempotencyKey;
  final DateTime occurredAt;
  final DateTime createdAt;
  final int attempts;
  final DateTime? nextAttemptAt;
  final OutboxStatus status;
  final String? lastError;
  final int? lastStatusCode;
  final String featureTag;
  final String label;
  final Map<String, String> meta;

  const OutboxItem({
    required this.id,
    required this.seq,
    required this.userId,
    required this.tenant,
    required this.method,
    required this.path,
    required this.idempotencyKey,
    required this.occurredAt,
    required this.createdAt,
    required this.featureTag,
    required this.label,
    this.query,
    this.jsonBody,
    this.attachments = const [],
    this.attempts = 0,
    this.nextAttemptAt,
    this.status = OutboxStatus.pending,
    this.lastError,
    this.lastStatusCode,
    this.meta = const {},
  });

  bool belongsTo(String userId, String tenant) =>
      this.userId == userId && this.tenant == tenant;

  bool isDue(DateTime now) =>
      status == OutboxStatus.pending &&
      (nextAttemptAt == null || !nextAttemptAt!.isAfter(now));

  OutboxItem copyWith({
    String? path,
    Map<String, dynamic>? query,
    dynamic jsonBody,
    List<OutboxAttachment>? attachments,
    int? attempts,
    DateTime? nextAttemptAt,
    bool clearNextAttempt = false,
    OutboxStatus? status,
    String? lastError,
    bool clearError = false,
    int? lastStatusCode,
  }) {
    return OutboxItem(
      id: id,
      seq: seq,
      userId: userId,
      tenant: tenant,
      method: method,
      path: path ?? this.path,
      query: query ?? this.query,
      jsonBody: jsonBody ?? this.jsonBody,
      attachments: attachments ?? this.attachments,
      idempotencyKey: idempotencyKey,
      occurredAt: occurredAt,
      createdAt: createdAt,
      attempts: attempts ?? this.attempts,
      nextAttemptAt:
          clearNextAttempt ? null : (nextAttemptAt ?? this.nextAttemptAt),
      status: status ?? this.status,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastStatusCode: clearError ? null : (lastStatusCode ?? this.lastStatusCode),
      featureTag: featureTag,
      label: label,
      meta: meta,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seq': seq,
        'userId': userId,
        'tenant': tenant,
        'method': method,
        'path': path,
        'query': query,
        'jsonBody': jsonBody,
        'attachments': [for (final a in attachments) a.toJson()],
        'idempotencyKey': idempotencyKey,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'attempts': attempts,
        'nextAttemptAt': nextAttemptAt?.toUtc().toIso8601String(),
        'status': status.name,
        'lastError': lastError,
        'lastStatusCode': lastStatusCode,
        'featureTag': featureTag,
        'label': label,
        'meta': meta,
      };

  factory OutboxItem.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final rawMeta = json['meta'];
    final created = DateTime.tryParse('${json['createdAt']}')?.toLocal() ??
        DateTime.now();
    return OutboxItem(
      id: json['id'] as String,
      seq: (json['seq'] as num?)?.toInt() ?? created.microsecondsSinceEpoch,
      userId: (json['userId'] as String?) ?? '',
      tenant: (json['tenant'] as String?) ?? '',
      method: (json['method'] as String?)?.toUpperCase() ?? 'POST',
      path: json['path'] as String,
      query: (json['query'] as Map?)?.cast<String, dynamic>(),
      jsonBody: json['jsonBody'],
      attachments: rawAttachments is List
          ? [
              for (final a in rawAttachments)
                if (a is Map)
                  OutboxAttachment.fromJson(a.cast<String, dynamic>()),
            ]
          : const [],
      idempotencyKey: (json['idempotencyKey'] as String?) ?? json['id'] as String,
      occurredAt:
          DateTime.tryParse('${json['occurredAt']}')?.toLocal() ?? created,
      createdAt: created,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      nextAttemptAt: json['nextAttemptAt'] == null
          ? null
          : DateTime.tryParse('${json['nextAttemptAt']}')?.toLocal(),
      status: OutboxStatus.parse(json['status'] as String?),
      lastError: json['lastError'] as String?,
      lastStatusCode: (json['lastStatusCode'] as num?)?.toInt(),
      featureTag: (json['featureTag'] as String?) ?? 'other',
      label: (json['label'] as String?) ?? 'Saved change',
      meta: rawMeta is Map
          ? rawMeta.map((k, v) => MapEntry('$k', '$v'))
          : const {},
    );
  }
}
