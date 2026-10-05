import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/formatting/web_formats.dart';
import '../domain/entities/daily_activity.dart';

/// The web badge variants used on Daily Activity.
enum DailyActivityTone { success, warning, danger, info, cyan, purple, neutral }

extension DailyActivityToneColors on DailyActivityTone {
  Color get foreground => switch (this) {
        DailyActivityTone.success => AppColors.activeGreen,
        DailyActivityTone.warning => AppColors.urgentAmber,
        DailyActivityTone.danger => AppColors.criticalRed,
        DailyActivityTone.info => AppColors.infoBlue,
        DailyActivityTone.cyan => AppColors.secondaryTeal,
        DailyActivityTone.purple => AppColors.nightPurple,
        DailyActivityTone.neutral => AppColors.textSecondary,
      };

  Color get background => switch (this) {
        DailyActivityTone.success => AppColors.activeBackground,
        DailyActivityTone.warning => AppColors.urgentBackground,
        DailyActivityTone.danger => AppColors.criticalBackgroundSoft,
        DailyActivityTone.info => AppColors.infoBackground,
        DailyActivityTone.cyan => AppColors.quickActionCreateShiftBg,
        DailyActivityTone.purple => AppColors.nightBackground,
        DailyActivityTone.neutral => AppColors.filterButtonBackground,
      };
}

abstract final class DailyActivityLabels {
  /// Form and filter labels (web `et`).
  static const types = <(String, String)>[
    ('personal_activity', 'Personal activity'),
    ('health_observation', 'Health observation'),
    ('medication_related', 'Medication related'),
    ('care_activity', 'Care activity'),
    ('behaviour_update', 'Behaviour update'),
    ('school', 'School'),
    ('program', 'Programme'),
    ('work', 'Work'),
    ('other', 'Other'),
  ];

  /// "How it went" labels (web `ea`).
  static const statuses = <(String, String)>[
    ('completed', 'Completed'),
    ('pending_review', 'Pending review'),
    ('reviewed', 'Reviewed'),
    ('refused', 'Refused'),
    ('partially_completed', 'Partly done'),
    ('unable_to_complete', 'Could not be done'),
    ('present', 'Present'),
    ('absent', 'Absent'),
  ];

  static const dateRanges = <(String, String)>[
    ('', 'Any date'),
    ('today', 'Today'),
    ('week', 'This week'),
    ('month', 'This month'),
  ];

  static String humanise(String? value) => WebFormat.humanise(value);

  static DailyActivityTone typeTone(String type) => switch (type) {
        'personal_activity' => DailyActivityTone.info,
        'health_observation' => DailyActivityTone.cyan,
        'medication_related' => DailyActivityTone.warning,
        'care_activity' => DailyActivityTone.success,
        'behaviour_update' => DailyActivityTone.purple,
        _ => DailyActivityTone.neutral,
      };

  static DailyActivityTone statusTone(String status) => switch (status) {
        'completed' || 'present' => DailyActivityTone.success,
        'reviewed' => DailyActivityTone.info,
        'pending_review' || 'partially_completed' => DailyActivityTone.warning,
        'refused' || 'unable_to_complete' || 'absent' => DailyActivityTone.danger,
        _ => DailyActivityTone.neutral,
      };

  static String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String month(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', //
    'August', 'September', 'October', 'November', 'December',
  ];

  static String monthName(int month) => _months[month - 1];

  /// `2026-09` → `September 2026`.
  static String monthLabel(String value) {
    final parts = value.split('-');
    final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (m == null || m < 1 || m > 12) return value;
    return '${_months[m - 1]} ${parts[0]}';
  }

  /// `from` / `to` for the registry date filter; weeks start on Monday.
  static (String?, String?) range(String? key, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (key) {
      'today' => (ymd(today), ymd(today)),
      'week' => (ymd(today.subtract(Duration(days: today.weekday - 1))), ymd(today)),
      'month' => (ymd(DateTime(today.year, today.month)), ymd(today)),
      _ => (null, null),
    };
  }

  /// `YYYY-MM` → first and last day of that month.
  static (String?, String?) monthBounds(String value) {
    final parts = value.split('-');
    final y = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (y == null || m == null) return (null, null);
    final last = DateTime(y, m + 1, 0).day;
    return ('$value-01', '$value-${last.toString().padLeft(2, '0')}');
  }

  static String initials(String name) => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0])
      .join()
      .toUpperCase();

  /// Day the record is filed to; `occurredAt` wins when present.
  static String date(DailyActivity a) {
    if (a.occurredAt != null) return WebFormat.date(a.occurredAt);
    final d = DateTime.tryParse(a.activityDate);
    return d == null ? '—' : WebFormat.date(d);
  }

  static String time(DailyActivity a) =>
      a.occurredAt == null ? '' : WebFormat.time(a.occurredAt);

  static String dateTime(DailyActivity a) {
    final t = time(a);
    return t.isEmpty ? date(a) : '${date(a)} · $t';
  }

  static String stamp(DateTime at) => '${WebFormat.date(at)} · ${WebFormat.time(at)}';
}
