import 'package:flutter/foundation.dart';

import 'medication_enums.dart';

/// A single card in the "Missed" tab's "Missed Medications" list.
@immutable
class MissedMedication {
  final String id;
  final String residentName;
  final String residentInitials;
  final AvatarPalette avatarColor;
  final String medicationName;
  final String dose;
  final String scheduledTime;
  final String missedTimeAgo;
  final String assigneeName;
  final String assigneeInitials;
  final AvatarPalette assigneeAvatarColor;
  final bool isCritical;

  const MissedMedication({
    required this.id,
    required this.residentName,
    required this.residentInitials,
    required this.avatarColor,
    required this.medicationName,
    required this.dose,
    required this.scheduledTime,
    required this.missedTimeAgo,
    required this.assigneeName,
    required this.assigneeInitials,
    required this.assigneeAvatarColor,
    this.isCritical = false,
  });
}
