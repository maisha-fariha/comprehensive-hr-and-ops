import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Foreground / background pair for the web's badge variants.
class MarTone {
  final Color foreground;
  final Color background;

  const MarTone(this.foreground, this.background);

  static const success = MarTone(AppColors.activeGreen, AppColors.activeBackground);
  static const warning = MarTone(AppColors.urgentAmber, AppColors.urgentBackground);
  static const danger = MarTone(AppColors.criticalRed, AppColors.criticalBackgroundSoft);
  static const info = MarTone(AppColors.infoBlue, AppColors.infoBackground);
  static const neutral = MarTone(AppColors.textSecondary, AppColors.filterButtonBackground);
  static const purple = MarTone(Color(0xFF7656D6), Color(0xFFF1EAFE));
}

/// A `(value, label)` choice.
typedef MarChoice = (String, String);

abstract final class MedicationLabels {
  static const Map<String, String> states = {
    'given': 'Given',
    'late': 'Given late',
    'due': 'Due now',
    'upcoming': 'Upcoming',
    'overdue': 'Overdue',
    'missed': 'Missed',
    'refused': 'Refused',
    'withheld': 'Withheld',
    'not_available': 'Not available',
  };

  static MarTone stateTone(String? state) => switch (state) {
        'given' => MarTone.success,
        'late' || 'refused' => MarTone.warning,
        'due' || 'withheld' => MarTone.info,
        'overdue' || 'missed' || 'not_available' => MarTone.danger,
        _ => MarTone.neutral,
      };

  /// The resident chart colours its pills differently from the registry.
  static MarTone chartStateTone(String state) => switch (state) {
        'given' => MarTone.success,
        'due' || 'withheld' || 'not_available' => MarTone.warning,
        'overdue' || 'missed' || 'refused' => MarTone.danger,
        _ => MarTone.neutral,
      };

  /// Administration status → registry state (Given tab outcome).
  static const Map<String, String> outcomeState = {
    'administered': 'given',
    'refused': 'refused',
    'missed': 'missed',
    'withheld': 'withheld',
    'not_available': 'not_available',
  };

  static const String anyStatus = '';

  static const List<MarChoice> statusFilter = [
    (anyStatus, 'Any status'),
    ('given', 'Given'),
    ('late', 'Given late'),
    ('due', 'Due now'),
    ('upcoming', 'Upcoming'),
    ('overdue', 'Overdue'),
    ('missed', 'Missed'),
    ('refused', 'Refused'),
    ('withheld', 'Withheld'),
    ('not_available', 'Not available'),
  ];

  static const List<MarChoice> doseReasons = [
    ('patient_refused', 'Resident refused'),
    ('resident_asleep', 'Resident asleep'),
    ('npo_fasting', 'Nil by mouth / fasting'),
    ('vomiting', 'Vomiting'),
    ('hospitalized', 'In hospital'),
    ('drug_unavailable', 'None in stock'),
    ('clinical_hold', 'Withheld on clinical advice'),
    ('other', 'Other — say below'),
  ];

  static const List<MarChoice> outcomes = [
    ('administered', 'Administered'),
    ('refused', 'Refused by resident'),
    ('withheld', 'Withheld — clinical decision'),
    ('not_available', 'Not available — none in stock'),
    ('missed', 'Missed'),
  ];

  /// `(field, label, description)` of the five verification checks.
  static const List<(String, String, String)> safetyChecks = [
    ('identityVerified', 'Patient identity verification', 'Resident confirmed by name and record.'),
    ('medicationVerified', 'Medication verification', 'Drug matches the prescribed order.'),
    ('dosageVerified', 'Dosage verification', 'Dose and strength match the prescription.'),
    ('routeVerified', 'Route verification', 'Given by the route prescribed.'),
    ('timeVerified', 'Time verification', 'Given within the window for this round.'),
  ];

  /// Live-preview names of the same checks.
  static const List<(String, String)> rights = [
    ('identityVerified', 'Right Resident'),
    ('medicationVerified', 'Right Medication'),
    ('dosageVerified', 'Right Dose'),
    ('routeVerified', 'Right Route'),
    ('timeVerified', 'Right Time'),
  ];

  /// `(field, label, placeholder)`.
  static const List<(String, String, String)> vitals = [
    ('bloodPressure', 'Blood pressure', '120/80'),
    ('heartRate', 'Heart rate', '72 bpm'),
    ('temperature', 'Temperature', '36.8 °C'),
    ('bloodSugar', 'Blood sugar', '5.4 mmol/L'),
  ];

  static const List<MarChoice> frequencies = [
    ('daily', 'Every day'),
    ('weekly', 'Weekly'),
    ('custom', 'Something else'),
  ];

  static const List<(int, String)> weekdays = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (0, 'Sun'),
  ];

  /// `(id, label, description)` of the Record Administration steps.
  static const List<(String, String, String)> steps = [
    ('medicationInformation', 'Medicines', 'Resident & every medicine given'),
    ('safetyCheck', 'Safety Check', 'Confirm the six checks'),
    ('documentation', 'Documentation', 'Evidence & final notes'),
  ];

  static const Map<String, String> stepTips = {
    'medicationInformation':
        'The medicine list is scoped to whoever is chosen as the resident, so the two cannot disagree.',
    'safetyCheck':
        'The six checks are stored with every dose that was actually given, and a dose given unchecked is what an audit looks for.',
    'documentation':
        'Evidence is filed against the resident in Documents, where a regulator looks for it.',
  };

  static String label(List<MarChoice> choices, String value) =>
      choices.firstWhere((c) => c.$1 == value, orElse: () => (value, value)).$2;

  /// The web `humanise`: underscores and dashes to spaces, first letter up.
  static String humanise(String? value) {
    if (value == null || value.isEmpty) return '—';
    final t = value.replaceAll(RegExp(r'[_-]+'), ' ');
    return t[0].toUpperCase() + t.substring(1);
  }

  static const List<Color> _palette = [
    Color(0xFF2E90FA),
    Color(0xFF12B76A),
    Color(0xFFF79009),
    Color(0xFF7656D6),
    Color(0xFFF04438),
    Color(0xFF06AED4),
  ];

  /// Stable colour per id, the same hash the web uses.
  static Color colorFor(String id) {
    var t = 0;
    for (final unit in id.codeUnits) {
      t = (31 * t + unit) % 997;
    }
    return _palette[t % _palette.length];
  }

  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    return (parts[0][0] + (parts.length > 1 ? parts[1][0] : '')).toUpperCase();
  }

  /// Morning before 12, Afternoon before 17, Evening before 21, else Night.
  static String slotFor(String hhmm) {
    final hour = int.tryParse(hhmm.split(':').first);
    if (hour == null || hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String time(DateTime value) {
    final l = value.toLocal();
    return '${_two(l.hour)}:${_two(l.minute)}';
  }

  /// The web `formatDateTime`: `dd/MM/yyyy HH:mm`.
  static String dateTime(DateTime? value) {
    if (value == null) return '—';
    final l = value.toLocal();
    return '${_two(l.day)}/${_two(l.month)}/${l.year} ${time(l)}';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Given-tab stamp: `01 Oct, 08:15`.
  static String shortStamp(DateTime? value) {
    if (value == null) return '—';
    final l = value.toLocal();
    return '${_two(l.day)} ${_months[l.month - 1]}, ${time(l)}';
  }

  static String day(DateTime value) =>
      '${value.year}-${_two(value.month)}-${_two(value.day)}';
}
