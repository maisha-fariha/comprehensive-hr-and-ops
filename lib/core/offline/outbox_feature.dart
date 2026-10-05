/// Classifies API writes for the outbox: feature tag, human label, whether
/// the write may ever be queued, and whether its timing matters.
abstract final class OutboxFeature {
  static const String dailyLogs = 'daily-logs';
  static const String mar = 'mar';
  static const String medications = 'medications';
  static const String attendance = 'attendance';
  static const String tasks = 'tasks';
  static const String recurringChecks = 'recurring-checks';
  static const String incidents = 'incidents';
  static const String handovers = 'handovers';
  static const String activities = 'activities';
  static const String schedule = 'schedule';
  static const String appointments = 'appointments';
  static const String messages = 'messages';
  static const String support = 'support';
  static const String settings = 'settings';
  static const String other = 'other';

  static const Set<String> timeSensitive = {
    dailyLogs,
    mar,
    attendance,
    incidents,
    activities,
    handovers,
  };

  /// Paths that must never be queued: auth/session, tenant lookup, device
  /// registration (would replay under another session), payments and raw
  /// uploads (staged separately).
  static bool isNeverQueued(String path) {
    final p = path.toLowerCase();
    return p.contains('/mobile/auth') ||
        p.contains('/public/tenant') ||
        p.contains('/auth/login') ||
        p.contains('/auth/logout') ||
        p.contains('/auth/avatar') ||
        p.contains('change-password') ||
        p.contains('/token/refresh') ||
        p.contains('/otp') ||
        p.startsWith('/devices') ||
        p.contains('/payments') ||
        p.contains('/billing') ||
        p.contains('/subscription') ||
        p == '/uploads' ||
        p.startsWith('/uploads/') ||
        p.contains('/exports');
  }

  static String tagFor(String path) {
    final p = path.toLowerCase();
    if (p.startsWith('/daily-logs')) return dailyLogs;
    if (p.startsWith('/mar')) return mar;
    if (p.startsWith('/medications') || p.startsWith('/prn-medications')) {
      return medications;
    }
    if (p.startsWith('/attendance')) return attendance;
    if (p.startsWith('/tasks')) return tasks;
    if (p.startsWith('/recurring-checks')) return recurringChecks;
    if (p.startsWith('/incidents')) return incidents;
    if (p.startsWith('/shift-handovers')) return handovers;
    if (p.startsWith('/client-activities')) return activities;
    if (p.startsWith('/shifts') || p.startsWith('/shift-swaps')) {
      return schedule;
    }
    if (p.contains('appointments')) return appointments;
    if (p.contains('messages') || p.startsWith('/conversations')) {
      return messages;
    }
    if (p.contains('tickets')) return support;
    if (p.contains('notification-preferences') || p.startsWith('/residences')) {
      return settings;
    }
    return other;
  }

  static String labelFor(String method, String path) {
    final m = method.toUpperCase();
    final p = path.toLowerCase();
    final tag = tagFor(path);
    switch (tag) {
      case dailyLogs:
        if (p.contains('/amendments')) return 'Daily note amendment';
        return m == 'POST' ? 'New daily note' : 'Daily note update';
      case mar:
        return 'Medication dose record';
      case medications:
        return m == 'POST' ? 'New medication' : 'Medication update';
      case attendance:
        if (p.endsWith('/check-in')) return 'Clock in';
        if (p.endsWith('/check-out')) return 'Clock out';
        if (p.endsWith('/break/start')) return 'Break start';
        if (p.endsWith('/break/end')) return 'Break end';
        return 'Attendance record';
      case tasks:
        if (p.contains('/notes')) return 'Task note';
        return m == 'POST' ? 'New task' : 'Task update';
      case recurringChecks:
        return 'Recurring check';
      case incidents:
        if (p.contains('/acknowledge')) return 'Incident acknowledgement';
        if (p.contains('/investigation')) return 'Incident investigation';
        return m == 'POST' ? 'New incident' : 'Incident update';
      case handovers:
        if (p.contains('/acknowledge')) return 'Handover acknowledgement';
        return m == 'DELETE' ? 'Handover removal' : 'Shift handover';
      case activities:
        return 'Resident activity';
      case schedule:
        if (p.contains('/bids')) return 'Shift bid';
        return 'Shift swap';
      case appointments:
        if (p.endsWith('/cancel')) return 'Appointment cancellation';
        if (p.endsWith('/reschedule')) return 'Appointment reschedule';
        return 'Appointment request';
      case messages:
        return 'Message';
      case support:
        return 'Support ticket';
      case settings:
        return 'Settings change';
      default:
        return 'Saved change';
    }
  }

  static String displayName(String tag) {
    switch (tag) {
      case dailyLogs:
        return 'Daily logs';
      case mar:
        return 'Medication (MAR)';
      case medications:
        return 'Medications';
      case attendance:
        return 'Attendance';
      case tasks:
        return 'Tasks';
      case recurringChecks:
        return 'Recurring checks';
      case incidents:
        return 'Incidents';
      case handovers:
        return 'Handovers';
      case activities:
        return 'Activities';
      case schedule:
        return 'Schedule';
      case appointments:
        return 'Appointments';
      case messages:
        return 'Messages';
      case support:
        return 'Support';
      case settings:
        return 'Settings';
      default:
        return 'Other';
    }
  }
}
