import 'package:flutter/foundation.dart';

import 'medication_enums.dart';

/// A single card in the "Refused" tab's "Refused Medications" list.
@immutable
class RefusedMedication {
  final String id;
  final String residentName;
  final String residentInitials;
  final AvatarPalette avatarColor;
  final String medicationName;
  final String dose;
  final String refusedTime;
  final String reason;
  final String reportedByName;
  final String reportedByInitials;
  final AvatarPalette reportedByAvatarColor;
  final bool needsFollowUp;

  const RefusedMedication({
    required this.id,
    required this.residentName,
    required this.residentInitials,
    required this.avatarColor,
    required this.medicationName,
    required this.dose,
    required this.refusedTime,
    required this.reason,
    required this.reportedByName,
    required this.reportedByInitials,
    required this.reportedByAvatarColor,
    this.needsFollowUp = false,
  });
}
