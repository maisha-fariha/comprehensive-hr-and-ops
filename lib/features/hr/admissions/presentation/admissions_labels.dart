import 'package:gems_core/gems_core.dart';

import '../../../../core/formatting/web_formats.dart';
import 'widgets/admissions_common.dart';

/// Web copy and enums for `/dashboard/admissions`.
abstract final class AdmissionsLabels {
  static const List<(String, String)> stages = [
    ('new', 'New'),
    ('screening', 'Screening'),
    ('waitlisted', 'Waitlisted'),
    ('assessment', 'Assessment'),
    ('admitted', 'Admitted'),
    ('declined', 'Declined'),
    ('withdrawn', 'Withdrawn'),
  ];

  /// "Move it on" leaves out the closing stages; those have their own actions.
  static const List<(String, String)> openStages = [
    ('new', 'New'),
    ('screening', 'Screening'),
    ('waitlisted', 'Waitlisted'),
    ('assessment', 'Assessment'),
  ];

  static const List<(String, String)> admissionTypes = [
    ('new_resident', 'New resident'),
    ('transfer', 'Transfer'),
    ('temporary', 'Temporary stay'),
    ('respite', 'Respite care'),
  ];

  static const List<(String, String)> answerTypes = [
    ('text', 'Text'),
    ('textarea', 'Long text'),
    ('number', 'Number'),
    ('date', 'Date'),
    ('select', 'Choice'),
    ('checkbox', 'Yes / no'),
  ];

  static const List<(String, String)> carryOverTargets = [
    ('none', 'Keep on the referral'),
    ('medical', "Resident's medical information"),
    ('care_plan', "Resident's care plan"),
    ('funding_source', 'Funding source'),
    ('room_number', 'Room number'),
  ];

  static const Map<String, String> _events = {
    'created': 'Referral received',
    'status_changed': 'Stage changed',
    'assessed': 'Assessed',
    'document_added': 'Document attached',
    'checklist_updated': 'Checklist updated',
    'admitted': 'Admitted',
    'declined': 'Declined',
  };

  static String event(String value) => _events[value] ?? value;

  static String label(List<(String, String)> options, String? value) =>
      options.where((o) => o.$1 == value).map((o) => o.$2).firstOrNull ??
      WebFormat.humanise(value);

  static AdmissionTone stageTone(String status) => switch (status) {
        'new' => AdmissionTone.info,
        'screening' => AdmissionTone.cyan,
        'waitlisted' => AdmissionTone.warning,
        'assessment' => AdmissionTone.purple,
        'admitted' => AdmissionTone.success,
        'declined' => AdmissionTone.danger,
        _ => AdmissionTone.neutral,
      };

  /// "Waiting" column: whole days since waitlisting, `Today`, or `—`.
  static String waiting(DateTime? since, {DateTime? now}) {
    if (since == null) return '—';
    final days =
        (now ?? DateTime.now()).difference(since).inMilliseconds ~/ 86400000;
    return days <= 0 ? 'Today' : '${days}d';
  }

  static String planLimit(int limit, int current) =>
      'This plan allows $limit residents and $current are already active. '
      'Admitting needs a place freed or the plan upgraded.';

  /// The web `toUserMessage`, plus its plan-limit copy.
  static String error(AppError error) {
    if (error is ApiError) {
      final data = error.responseData;
      final nested = data?['error'];
      final body = nested is Map ? nested : data;
      if (body != null && body['code'] == 'PLAN_LIMIT_EXCEEDED') {
        final details = body['details'];
        if (details is Map &&
            details['limit'] is num &&
            details['current'] is num) {
          return planLimit(
            (details['limit'] as num).toInt(),
            (details['current'] as num).toInt(),
          );
        }
      }
    }
    return error.message;
  }

  /// `Full name` lower-cased and slugged into a field key, max 64 chars.
  static String slug(String label) {
    final s = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return s.length > 64 ? s.substring(0, 64) : s;
  }
}
