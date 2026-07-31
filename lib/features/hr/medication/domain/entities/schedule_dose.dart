import 'package:flutter/foundation.dart';

import 'medication_enums.dart';

/// A single row in the "Due" tab's "Today's Medication Schedule" list
/// (used for both the "Priority Medications" and "Later Today" sections).
@immutable
class ScheduleDose {
  final String id;
  final String residentName;
  final String residentInitials;
  final AvatarPalette avatarColor;
  final String medicationName;
  final String dose;
  final String scheduledTime;
  final String assigneeName;
  final String assigneeInitials;
  final AvatarPalette assigneeAvatarColor;
  final DoseStatus status;

  const ScheduleDose({
    required this.id,
    required this.residentName,
    required this.residentInitials,
    required this.avatarColor,
    required this.medicationName,
    required this.dose,
    required this.scheduledTime,
    required this.assigneeName,
    required this.assigneeInitials,
    required this.assigneeAvatarColor,
    required this.status,
  });
}
