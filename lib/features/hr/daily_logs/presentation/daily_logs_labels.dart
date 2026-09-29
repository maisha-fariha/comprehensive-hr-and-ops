import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/formatting/web_formats.dart';

enum DailyLogTone { success, warning, danger, info, neutral, cyan, purple }

extension DailyLogToneColors on DailyLogTone {
  Color get foreground => switch (this) {
        DailyLogTone.success => AppColors.activeGreen,
        DailyLogTone.warning => AppColors.urgentAmber,
        DailyLogTone.danger => AppColors.criticalRed,
        DailyLogTone.info => AppColors.infoBlue,
        DailyLogTone.neutral => AppColors.textSecondary,
        DailyLogTone.cyan => AppColors.secondaryTeal,
        DailyLogTone.purple => AppColors.nightPurple,
      };

  Color get background => switch (this) {
        DailyLogTone.success => AppColors.activeBackground,
        DailyLogTone.warning => AppColors.urgentBackground,
        DailyLogTone.danger => AppColors.criticalBackgroundSoft,
        DailyLogTone.info => AppColors.infoBackground,
        DailyLogTone.neutral => AppColors.filterButtonBackground,
        DailyLogTone.cyan => AppColors.secondaryTeal.withValues(alpha: 0.1),
        DailyLogTone.purple => AppColors.nightBackground,
      };
}

/// Option lists, pill tones and formatting from the web Daily Logs page.
abstract final class DailyLogLabels {
  static const tabs = ['To review', 'Missing', 'Resident day view', 'House activity'];

  static const shifts = [
    ('morning', 'Morning'),
    ('afternoon', 'Afternoon'),
    ('night', 'Night'),
    ('day', 'Day (full)'),
  ];

  static const logTypes = [
    ('care_note', 'Care note'),
    ('behaviour', 'Behaviour'),
    ('sleep_mood', 'Sleep / mood'),
    ('nutrition', 'Nutrition'),
    ('incident_followup', 'Incident follow-up'),
  ];

  static const moods = [
    ('settled', 'Settled'),
    ('cheerful', 'Cheerful'),
    ('withdrawn', 'Withdrawn'),
    ('anxious', 'Anxious'),
    ('agitated', 'Agitated'),
  ];

  static const sleeps = [
    ('slept_well', 'Slept well'),
    ('broken', 'Broken sleep'),
    ('restless', 'Restless'),
    ('awake_most', 'Awake most of the night'),
  ];

  static const hygiene = [
    ('independent', 'Independent'),
    ('prompted', 'Prompted'),
    ('assisted', 'Assisted'),
    ('full_support', 'Full support'),
    ('declined', 'Declined'),
  ];

  static const flagCategories = [
    ('behaviour', 'Behaviour'),
    ('medical', 'Medical'),
    ('safeguarding', 'Safeguarding'),
    ('medication', 'Medication'),
    ('environment', 'Environment'),
    ('other', 'Other'),
  ];

  static const shiftStatuses = {
    'open': 'Not started',
    'in_progress': 'In progress',
    'completed': 'Completed',
    'locked': 'Signed off',
  };

  static const shiftStatusTones = {
    'open': DailyLogTone.danger,
    'in_progress': DailyLogTone.warning,
    'completed': DailyLogTone.success,
    'locked': DailyLogTone.neutral,
  };

  static const moduleTones = {
    'handovers': DailyLogTone.info,
    'scheduling': DailyLogTone.purple,
    'attendance': DailyLogTone.neutral,
    'mar': DailyLogTone.success,
    'inventory': DailyLogTone.warning,
    'tasks': DailyLogTone.cyan,
  };

  static const flagTones = {
    'medication': DailyLogTone.danger,
    'safeguarding': DailyLogTone.danger,
    'medical': DailyLogTone.warning,
    'behaviour': DailyLogTone.cyan,
    'environment': DailyLogTone.info,
    'other': DailyLogTone.neutral,
  };

  static const flagDots = {
    'medication': AppColors.criticalRed,
    'safeguarding': AppColors.criticalRed,
    'medical': Color(0xFFE9A23B),
    'behaviour': Color(0xFF0E7C7B),
    'environment': Color(0xFF61758D),
  };

  static String labelOf(List<(String, String)> options, String? value) =>
      options.firstWhere((o) => o.$1 == value, orElse: () => ('', '')).$2;

  static String capitalise(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  /// `communityOuting` → `Community outing`.
  static String camel(String value) => capitalise(
        value.replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m[1]}').toLowerCase(),
      );

  /// `handover_acknowledged` → `Handover acknowledged`.
  static String underscores(String value) => capitalise(value.replaceAll('_', ' '));

  static String dateTime(DateTime? value) => WebFormat.dateTime(value, empty: '');

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// `Sep 17 – Sep 23`, or one date when both ends match.
  static String window(String from, String to) {
    String one(String key) {
      final d = DateTime.tryParse(key);
      return d == null ? key : '${_months[d.month - 1]} ${d.day}';
    }

    return from == to ? one(from) : '${one(from)} – ${one(to)}';
  }

  /// `29 Sep, 08:15` (Priority Notes raised stamp).
  static String raised(DateTime? value) {
    if (value == null) return '';
    final l = value.toLocal();
    return '${l.day} ${_months[l.month - 1]}, ${WebFormat.time(l)}';
  }

  static (DailyLogTone, String) medication(String body) {
    final b = body.toLowerCase();
    if (b.contains('administered')) return (DailyLogTone.success, 'Medication given');
    if (b.contains('refused')) return (DailyLogTone.danger, 'Medication refused');
    if (b.contains('missed')) return (DailyLogTone.danger, 'Medication missed');
    if (b.contains('withheld')) return (DailyLogTone.danger, 'Medication withheld');
    return (DailyLogTone.info, 'Medication');
  }
}
