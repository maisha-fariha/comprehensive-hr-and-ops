import 'package:flutter/foundation.dart';

/// Compact analytics card from `GET /reports/analytics`.
@immutable
class ReportAnalyticsItem {
  final String id;
  final String title;
  final String valueLabel;
  final String subtitle;

  const ReportAnalyticsItem({
    required this.id,
    required this.title,
    required this.valueLabel,
    required this.subtitle,
  });
}
