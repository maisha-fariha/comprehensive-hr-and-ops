import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Web copy, option lists and formatting for the client directory.
abstract final class ClientsLabels {
  static const genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];
  static const careLevels = ['Low', 'Medium', 'High'];
  static const statuses = ['Active', 'Pending', 'Inactive'];
  static const fundingSources = [
    'Private Pay',
    'Medicaid',
    'Medicare',
    'Insurance',
    'Other',
  ];
  static const relationships = [
    'Parent',
    'Child',
    'Spouse',
    'Sibling',
    'Legal Guardian',
    'Other',
  ];

  static const pageSizes = [10, 25, 50];

  static const addDescription =
      'Create a secure client profile, assign residence details, and capture '
      'family, medical, and care planning information.';
  static const addStatusBar =
      'Required fields · Client records feed daily logs, MAR, incidents, '
      'appointments, documents, and reports.';

  static String planLimitTooltip(int current, int limit) =>
      'Plan limit reached ($current/$limit clients). Upgrade your plan to admit more.';

  static const stillRunning =
      'Export is still running — it will appear on the Reports page when it finishes.';

  /// The web `humanise`.
  static String humanise(String? value) {
    if (value == null || value.isEmpty) return '—';
    final text = value.replaceAll(RegExp(r'[_-]+'), ' ');
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Calendar date as the web shows it (`DD/MM/YYYY`), without a timezone
  /// shift for UTC-midnight dates.
  static String date(DateTime? value) {
    if (value == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  /// `YYYY-MM-DD`, the web's date-input value.
  static String dateInput(DateTime? value) {
    if (value == null) return '';
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static DateTime? parseDateInput(String value) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  /// `Intl.NumberFormat(..., { style: 'currency', currency: 'USD' })`.
  static String money(num? value) {
    if (value == null) return '—';
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final cents = parts[1] == '00' ? '' : '.${parts[1]}';
    return '${negative ? '-' : ''}\$$whole$cents';
  }

  static String quantity(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  /// Matches [value] against [options] ignoring case (`active` -> `Active`).
  static String matchOption(String? value, List<String> options) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '';
    for (final o in options) {
      if (o.toLowerCase() == v.toLowerCase()) return o;
    }
    return v;
  }

  static const _avatarColors = [
    Color(0xFFB4805A),
    Color(0xFF5C6B80),
    Color(0xFF2A5DA6),
    Color(0xFF3FA66D),
    Color(0xFF8C5AA6),
    Color(0xFFA65A5A),
  ];

  /// The web's per-client avatar colour (hash of the id).
  static Color avatarColor(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (31 * hash + unit) & 0xFFFFFFFF;
    }
    return _avatarColors[hash % _avatarColors.length];
  }
}

/// The web badge variants used by the directory.
enum ClientTone { success, warning, info, neutral, danger }

extension ClientToneColors on ClientTone {
  Color get foreground => switch (this) {
        ClientTone.success => AppColors.activeGreen,
        ClientTone.warning => AppColors.urgentAmber,
        ClientTone.info => AppColors.infoBlue,
        ClientTone.neutral => AppColors.textSecondary,
        ClientTone.danger => AppColors.criticalRed,
      };

  Color get background => switch (this) {
        ClientTone.success => AppColors.activeBackground,
        ClientTone.warning => AppColors.urgentBackground,
        ClientTone.info => AppColors.infoBackground,
        ClientTone.neutral => AppColors.filterButtonBackground,
        ClientTone.danger => AppColors.criticalBackgroundSoft,
      };

  static ClientTone forStatus(String status) =>
      switch (status.toLowerCase()) {
        'active' => ClientTone.success,
        'on_leave' || 'on leave' => ClientTone.warning,
        'pending' => ClientTone.info,
        _ => ClientTone.neutral,
      };
}
