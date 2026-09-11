import 'package:flutter/foundation.dart';

/// Trend insight row from `GET /reports/series?metric=…`.
@immutable
class ReportInsight {
  final String metric;
  final String title;
  final String trendLabel;
  final bool isUp;
  final String detail;

  const ReportInsight({
    required this.metric,
    required this.title,
    required this.trendLabel,
    required this.isUp,
    required this.detail,
  });
}
