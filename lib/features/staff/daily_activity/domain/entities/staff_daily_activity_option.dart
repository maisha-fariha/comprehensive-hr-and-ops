import 'package:flutter/foundation.dart';

@immutable
class StaffDailyActivityPersonOption {
  final String id;
  final String name;
  final String? subtitle;

  const StaffDailyActivityPersonOption({
    required this.id,
    required this.name,
    this.subtitle,
  });
}

/// API enums used by create + filters (web labels).
abstract final class StaffDailyActivityEnums {
  static const activityTypes = <(String, String)>[
    ('care_activity', 'Care activity'),
    ('personal_activity', 'Personal activity'),
    ('health_observation', 'Health observation'),
    ('medication_related', 'Medication related'),
    ('behaviour_update', 'Behaviour update'),
    ('school', 'School'),
    ('program', 'Program'),
    ('work', 'Work'),
    ('other', 'Other'),
  ];

  /// "How it went" — web wording.
  static const statuses = <(String, String)>[
    ('completed', 'Completed'),
    ('present', 'Present'),
    ('absent', 'Absent'),
    ('partially_completed', 'Partial'),
    ('refused', 'Refused'),
    ('unable_to_complete', 'Unable to complete'),
    ('pending_review', 'Pending review'),
    ('reviewed', 'Reviewed'),
  ];

  static String labelForType(String? value) {
    if (value == null || value.isEmpty) return '—';
    for (final entry in activityTypes) {
      if (entry.$1 == value) return entry.$2;
    }
    return value.replaceAll('_', ' ');
  }

  static String labelForStatus(String? value) {
    if (value == null || value.isEmpty) return '—';
    for (final entry in statuses) {
      if (entry.$1 == value) return entry.$2;
    }
    return value.replaceAll('_', ' ');
  }
}

enum StaffDailyActivityTab { registry, residentHistory }
