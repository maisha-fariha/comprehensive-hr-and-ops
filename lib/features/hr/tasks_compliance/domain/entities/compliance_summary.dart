import 'package:flutter/foundation.dart';

/// The "Overall Compliance" hero card at the top of the "Compliance" tab.
@immutable
class ComplianceSummary {
  final int percent;
  final String description;
  final String trendLabel;

  const ComplianceSummary({
    required this.percent,
    required this.description,
    required this.trendLabel,
  });
}
