import 'package:flutter/foundation.dart';

/// Staff training certificate nearing expiry
/// (`GET /training/certificates?expiryStatus=expiring&expiringWithinDays=30`).
@immutable
class ExpiringCertificate {
  final String id;
  final String staffName;
  final String title;
  final String expiryLabel;

  const ExpiringCertificate({
    required this.id,
    required this.staffName,
    required this.title,
    required this.expiryLabel,
  });
}
