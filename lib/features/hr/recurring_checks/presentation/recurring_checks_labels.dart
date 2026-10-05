import '../../attendance/presentation/widgets/attendance_record_card.dart';
import '../domain/entities/recurring_check.dart';

/// A reading field a check type records.
class CheckReadingField {
  final String key;
  final String label;
  final String? unit;
  final List<(String, String)>? options;

  const CheckReadingField(this.key, this.label, {this.unit, this.options});

  bool get isSelect => options != null;

  String get labelWithUnit => unit == null ? label : '$label ($unit)';
}

/// Option lists and wording from the web recurring checks page.
abstract final class CheckLabels {
  static const checkTypes = [
    ('vital_signs', 'Vital signs'),
    ('medication_related', 'Medication related'),
    ('health_observation', 'Health observation'),
    ('mobility', 'Mobility'),
    ('safety', 'Safety'),
    ('nutrition', 'Nutrition'),
    ('hydration', 'Hydration'),
    ('other', 'Other'),
  ];

  static const frequencies = [
    ('interval', 'Every N minutes'),
    ('daily', 'Daily, at set times'),
    ('weekly', 'Weekly, on set days'),
    ('monthly', 'Monthly, on a set date'),
  ];

  static const roles = [
    ('nurse', 'Nurse'),
    ('caregiver', 'Caregiver'),
    ('residence_manager', 'Residence manager'),
  ];

  static const weekdays = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (0, 'Sun'),
  ];

  static const statuses = [
    ('pending', 'Pending'),
    ('needs_assignment', 'Needs a nurse'),
    ('in_progress', 'In progress'),
    ('completed', 'Completed'),
    ('missed', 'Missed'),
    ('skipped', 'Skipped'),
    ('requires_review', 'Requires review'),
  ];

  static AttendanceTone statusTone(String status) => switch (status) {
        'pending' => AttendanceTone.info,
        'needs_assignment' || 'requires_review' => AttendanceTone.warning,
        'in_progress' => AttendanceTone.info,
        'completed' => AttendanceTone.success,
        'missed' => AttendanceTone.danger,
        _ => AttendanceTone.neutral,
      };

  static const outcomes = [
    ('normal', 'Normal'),
    ('needs_attention', 'Needs attention'),
    ('urgent', 'Urgent'),
  ];

  static AttendanceTone outcomeTone(String outcome) => switch (outcome) {
        'normal' => AttendanceTone.success,
        'needs_attention' => AttendanceTone.warning,
        'urgent' => AttendanceTone.danger,
        _ => AttendanceTone.neutral,
      };

  static String outcome(String value) =>
      outcomes.firstWhere((o) => o.$1 == value, orElse: () => (value, value)).$2;

  static const operators = [
    ('gt', 'is above'),
    ('gte', 'is at or above'),
    ('lt', 'is below'),
    ('lte', 'is at or below'),
    ('eq', 'is'),
    ('ne', 'is not'),
  ];

  static const severities = [
    ('needs_attention', 'Needs attention'),
    ('urgent', 'Urgent'),
  ];

  static const notifyRoles = [
    ('nurse', 'Nurse'),
    ('residence_manager', 'Residence manager'),
    ('manager', 'Manager'),
    ('tenant_admin', 'Tenant admin'),
  ];

  static const _meal = [
    ('all', 'All of it'),
    ('most', 'Most of it'),
    ('some', 'Some of it'),
    ('none', 'None'),
  ];

  static const _position = [
    ('left', 'Left side'),
    ('right', 'Right side'),
    ('back', 'On back'),
    ('chair', 'Chair'),
  ];

  static const Map<String, List<CheckReadingField>> readings = {
    'vital_signs': [
      CheckReadingField('systolic', 'Systolic', unit: 'mmHg'),
      CheckReadingField('diastolic', 'Diastolic', unit: 'mmHg'),
      CheckReadingField('pulse', 'Pulse', unit: 'bpm'),
      CheckReadingField('temperature', 'Temperature', unit: '°C'),
    ],
    'health_observation': [CheckReadingField('weight', 'Weight', unit: 'kg')],
    'hydration': [CheckReadingField('intakeMl', 'Fluid intake', unit: 'ml')],
    'nutrition': [CheckReadingField('intake', 'Meal taken', options: _meal)],
    'mobility': [CheckReadingField('position', 'Repositioned to', options: _position)],
  };

  static List<CheckReadingField> readingsFor(String? checkType) =>
      readings[checkType] ?? const [];

  static String labelOf<T>(List<(T, String)> options, T value) =>
      options.where((o) => o.$1 == value).firstOrNull?.$2 ?? '';

  /// `needs_assignment` → `Needs assignment`.
  static String humanise(String value) {
    final spaced = value.replaceAll('_', ' ');
    return spaced.isEmpty ? spaced : spaced[0].toUpperCase() + spaced.substring(1);
  }

  static String clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  /// `HH:mm` → minutes after midnight, or null.
  static int? minutesOf(String text) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(text);
    if (match == null) return null;
    return int.parse(match[1]!) * 60 + int.parse(match[2]!);
  }

  /// The web "How often" column.
  static String describeFrequency(CheckSchedule s) {
    final times = s.timesOfDay.map(clock).join(', ');
    switch (s.frequency) {
      case 'daily':
        return times.isEmpty ? 'Daily' : 'Daily at $times';
      case 'weekly':
        final days = s.weekdays
            .map((d) => labelOf(weekdays, d))
            .where((l) => l.isNotEmpty)
            .join(', ');
        return [days.isEmpty ? 'Weekly' : days, if (times.isNotEmpty) 'at $times'].join(' ');
      case 'monthly':
        return [
          s.dayOfMonth != null ? 'Day ${s.dayOfMonth} of each month' : 'Monthly',
          if (times.isNotEmpty) 'at $times',
        ].join(' ');
      default:
        return s.intervalMinutes != null
            ? 'Every ${s.intervalMinutes} minutes'
            : 'No schedule set';
    }
  }
}
