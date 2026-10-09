import '../../attendance/presentation/widgets/attendance_record_card.dart';
import '../domain/entities/residence_form.dart';

/// Web option lists, pill tones and wizard copy for the Residences module.
abstract final class ResidencesLabels {
  static const statusFilters = [
    ('active', 'Active'),
    ('archived', 'Archived'),
    ('under_renovation', 'Under renovation'),
  ];

  static const lifecycleStatuses = ['Active', 'Pending', 'Inactive'];

  /// Web `RESIDENCE_TYPE_OPTIONS` (value, label, description).
  static const residenceTypes = [
    ('Assisted Living', 'Assisted Living', 'Supported daily living'),
    ('Skilled Nursing', 'Nursing Home', '24/7 clinical care'),
    ('Memory Care', 'Memory Care', 'Dementia specialised'),
    ('Independent Living', 'Independent Living', 'Minimal assistance'),
    ('Group Home', 'Group Home', 'Everything in the group home'),
    ('Foster / Kinship Care', 'Foster / Kinship Care', 'Foster and kinship care home'),
  ];

  static const countries = ['United States', 'Canada'];

  static const timeZones = [
    ('America/Los_Angeles', 'America/Los_Angeles (PST)'),
    ('America/Denver', 'America/Denver (MST)'),
    ('America/Chicago', 'America/Chicago (CST)'),
    ('America/New_York', 'America/New_York (EST)'),
  ];

  static const serviceTypes = [
    'Residential Care',
    'Memory Care',
    'Skilled Nursing',
    'Respite Care',
  ];

  static const roomTypes = [
    ('single', 'Single'),
    ('double', 'Double'),
    ('twin', 'Twin'),
    ('suite', 'Suite'),
  ];

  static const residenceRoles = {
    'primary_manager': 'Primary manager',
    'assistant_manager': 'Assistant manager',
    'care_team': 'Care team',
    'staff': 'Staff',
  };

  static const residenceRoleOrder = [
    'primary_manager',
    'assistant_manager',
    'care_team',
    'staff',
  ];

  static AttendanceTone residenceRoleTone(String role) => switch (role) {
        'primary_manager' => AttendanceTone.warning,
        'assistant_manager' => AttendanceTone.success,
        'care_team' => AttendanceTone.info,
        _ => AttendanceTone.neutral,
      };

  /// Web list `S` status variants.
  static AttendanceTone statusTone(String status) =>
      switch (status.toLowerCase()) {
        'active' => AttendanceTone.success,
        'full' => AttendanceTone.danger,
        'under_renovation' ||
        'renovation' ||
        'pending' =>
          AttendanceTone.warning,
        _ => AttendanceTone.neutral,
      };

  static AttendanceTone lifecycleTone(String status) => switch (status) {
        'Active' => AttendanceTone.success,
        'Pending' => AttendanceTone.warning,
        _ => AttendanceTone.neutral,
      };

  static AttendanceTone shiftTone(String? status) => switch (status) {
        'scheduled' => AttendanceTone.success,
        'open' => AttendanceTone.warning,
        'cancelled' => AttendanceTone.danger,
        _ => AttendanceTone.neutral,
      };

  static String stepLabel(ResidenceFormStep step) => switch (step) {
        ResidenceFormStep.basic => 'Basic Information',
        ResidenceFormStep.address => 'Address & Location',
        ResidenceFormStep.capacity => 'Capacity & Operations',
        ResidenceFormStep.management => 'Management & Staff',
        ResidenceFormStep.review => 'Review & Create',
      };

  static String stepDescription(ResidenceFormStep step) => switch (step) {
        ResidenceFormStep.basic => 'Name, type & status',
        ResidenceFormStep.address => 'Address & GPS geofence',
        ResidenceFormStep.capacity => 'Beds & operating hours',
        ResidenceFormStep.management => 'Managers & care team',
        ResidenceFormStep.review => 'Confirm and register',
      };

  /// Setup Progress labels (web `eR`).
  static String progressLabel(ResidenceFormStep step) => switch (step) {
        ResidenceFormStep.basic => 'Basic information',
        ResidenceFormStep.address => 'Address & location',
        ResidenceFormStep.capacity => 'Capacity & operations',
        ResidenceFormStep.management => 'Management & staff',
        ResidenceFormStep.review => 'Review',
      };

  static String stepTip(ResidenceFormStep step) => switch (step) {
        ResidenceFormStep.basic =>
          'Residences created as Pending stay hidden from staff until an admin activates them.',
        ResidenceFormStep.address =>
          'Accurate GPS coordinates enable staff geofenced clock-in and location verification.',
        ResidenceFormStep.capacity =>
          'Occupied beds are calculated automatically from active client assignments.',
        ResidenceFormStep.management =>
          'The Primary Manager receives all escalations and compliance alerts for this residence.',
        ResidenceFormStep.review =>
          'Once created, the residence appears in the directory and can accept client assignments.',
      };

  static String humanise(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '';
    final spaced = text.replaceAll(RegExp(r'[_-]+'), ' ');
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  /// Web residence type option label (falls back to the raw enabled type).
  static String typeLabel(String value) {
    for (final (v, label, _) in residenceTypes) {
      if (v == value) return label;
    }
    return humanise(value);
  }

  static String? typeDescription(String value) {
    for (final (v, _, description) in residenceTypes) {
      if (v == value) return description;
    }
    return null;
  }
}
