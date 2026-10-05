import '../../../../core/formatting/web_formats.dart';
import '../../attendance/presentation/widgets/attendance_record_card.dart';

/// Web `emergency` labels and pill tones.
class EmergencyLabels {
  const EmergencyLabels._();

  static const List<(String, String)> types = [
    ('medical', 'Medical emergency'),
    ('fall', 'Fall'),
    ('behaviour', 'Resident behaviour'),
    ('missing_client', 'Missing resident'),
    ('safety', 'Safety concern'),
    ('fire', 'Fire or facility'),
    ('security', 'Security'),
    ('other', 'Other'),
  ];

  static const List<(String, String)> statuses = [
    ('active', 'Active'),
    ('acknowledged', 'Acknowledged'),
    ('in_progress', 'In progress'),
    ('resolved', 'Resolved'),
    ('cancelled', 'Cancelled'),
  ];

  static const Map<String, String> _priorities = {
    'critical': 'Critical',
    'high': 'High',
    'standard': 'Standard',
  };

  static const Map<String, String> _actions = {
    'raised': 'Alarm raised',
    'acknowledged': 'Acknowledged',
    'assigned': 'Assigned',
    'note': 'Note added',
    'status_changed': 'Status changed',
    'resolved': 'Resolved',
    'cancelled': 'Cancelled',
  };

  static String _lookup(List<(String, String)> list, String value) =>
      list.firstWhere((e) => e.$1 == value, orElse: () => (value, '')).$2;

  static String type(String value) {
    final label = _lookup(types, value);
    return label.isEmpty ? WebFormat.humanise(value) : label;
  }

  static String status(String value) {
    final label = _lookup(statuses, value);
    return label.isEmpty ? value : label;
  }

  static String priority(String value) => _priorities[value] ?? value;

  static String action(String value) => _actions[value] ?? value;

  static AttendanceTone statusTone(String value) => switch (value) {
        'active' => AttendanceTone.danger,
        'acknowledged' => AttendanceTone.warning,
        'in_progress' => AttendanceTone.info,
        'resolved' => AttendanceTone.success,
        _ => AttendanceTone.neutral,
      };

  static AttendanceTone priorityTone(String value) => switch (value) {
        'critical' => AttendanceTone.danger,
        'high' => AttendanceTone.warning,
        _ => AttendanceTone.neutral,
      };
}
