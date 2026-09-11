import 'package:flutter/foundation.dart';

/// Export row from `GET /reports/exports` (+ status/download helpers).
@immutable
class ReportExportItem {
  final String id;
  final String reportKey;
  final String format;
  final String status;
  final String createdLabel;
  final String? downloadUrl;

  const ReportExportItem({
    required this.id,
    required this.reportKey,
    required this.format,
    required this.status,
    required this.createdLabel,
    this.downloadUrl,
  });

  bool get isReady => status.toLowerCase() == 'ready';
}
