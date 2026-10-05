import 'package:flutter/foundation.dart';

import '../../../../../core/formatting/web_formats.dart';

/// One row of `GET /appointments`, with the web's derived labels.
@immutable
class HrAppointment {
  final String id;
  final String type;
  final String status;
  final String clientId;
  final String? clientName;
  final String? residenceId;
  final String? residenceName;
  final String? requesterName;
  final String? requesterEmail;
  final String? relationship;
  final DateTime? scheduledAt;
  final String? location;
  final String? purpose;
  final String? notes;
  final String? deciderName;
  final DateTime? decidedAt;
  final String? decisionReason;

  const HrAppointment({
    required this.id,
    required this.type,
    required this.status,
    this.clientId = '',
    this.clientName,
    this.residenceId,
    this.residenceName,
    this.requesterName,
    this.requesterEmail,
    this.relationship,
    this.scheduledAt,
    this.location,
    this.purpose,
    this.notes,
    this.deciderName,
    this.decidedAt,
    this.decisionReason,
  });

  static const statusLabels = {
    'pending': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'cancelled': 'Cancelled',
    'completed': 'Completed',
  };

  bool get isFamilyVisit => type == 'family_visit';

  /// `APT-` plus the first eight characters of the id, upper-cased.
  String get reference {
    final head = id.length > 8 ? id.substring(0, 8) : id;
    return 'APT-${head.toUpperCase()}';
  }

  String get client => clientName ?? '—';
  String get residence => residenceName ?? '—';
  String get requestedBy => requesterName ?? 'The home';
  String get relationshipLabel => relationship ?? '—';
  String get typeLabel => isFamilyVisit ? 'Family Visit' : 'External';
  String get statusLabel => statusLabels[status] ?? status;
  String get requestedDate =>
      scheduledAt == null ? 'No date proposed' : WebFormat.date(scheduledAt);
  String get time => scheduledAt == null ? '—' : WebFormat.time(scheduledAt);

  /// Only a pending family visit can be approved or declined.
  bool get isDecidable => isFamilyVisit && status == 'pending';

  bool get isLive => !const ['cancelled', 'rejected', 'completed'].contains(status);

  /// The "Purpose" column: purpose, else notes, else a dash.
  String get purposeColumn {
    if (purpose != null && purpose!.isNotEmpty) return purpose!;
    if (notes != null && notes!.isNotEmpty) return notes!;
    return '—';
  }
}

@immutable
class HrAppointmentPage {
  final List<HrAppointment> items;
  final int total;
  final int totalPages;

  const HrAppointmentPage({
    this.items = const [],
    this.total = 0,
    this.totalPages = 0,
  });
}

/// `GET /appointments/summary`.
@immutable
class HrAppointmentSummary {
  final int pending;
  final int approved;
  final int rejected;
  final int cancelled;
  final int completed;
  final int approvedToday;
  final int upcomingVisits;
  final int upcomingExternal;
  final int total;

  const HrAppointmentSummary({
    this.pending = 0,
    this.approved = 0,
    this.rejected = 0,
    this.cancelled = 0,
    this.completed = 0,
    this.approvedToday = 0,
    this.upcomingVisits = 0,
    this.upcomingExternal = 0,
    this.total = 0,
  });

  int get cancelledOrRejected => cancelled + rejected;
}

/// Query sent to `GET /appointments`; empty strings are left out.
@immutable
class HrAppointmentQuery {
  final int page;
  final int limit;
  final String? status;
  final String? type;
  final String? residenceId;
  final String? search;

  const HrAppointmentQuery({
    required this.page,
    required this.limit,
    this.status,
    this.type,
    this.residenceId,
    this.search,
  });
}

@immutable
class HrAppointmentOption {
  final String id;
  final String label;

  const HrAppointmentOption({required this.id, required this.label});
}

/// A resident in the form's picker, from `GET /clients`.
@immutable
class HrAppointmentClient {
  final String id;
  final String name;
  final String code;
  final String residence;
  final String residenceId;

  const HrAppointmentClient({
    required this.id,
    required this.name,
    this.code = '',
    this.residence = '',
    this.residenceId = '',
  });
}

/// One entry of today's daily log, shown as "Recent Daily Log Context".
@immutable
class HrAppointmentLogNote {
  final String id;
  final String body;
  final String? logType;
  final bool openFlag;
  final bool isSuperseded;
  final DateTime? at;
  final String? authorName;

  const HrAppointmentLogNote({
    required this.id,
    required this.body,
    this.logType,
    this.openFlag = false,
    this.isSuperseded = false,
    this.at,
    this.authorName,
  });

  /// The web's tag rules: an open flag is Behavior, otherwise by log type.
  String get tag {
    if (openFlag) return 'Behavior';
    final t = (logType ?? '').toLowerCase();
    if (t.contains('medic')) return 'Medication';
    if (t.contains('activ') || t.contains('social')) return 'Activity';
    if (t.contains('behav')) return 'Behavior';
    return 'General';
  }

  String get title => authorName ?? 'Care note';
}

/// What the create / edit form saves. Blank strings are already null.
@immutable
class HrAppointmentInput {
  final String type;
  final String clientId;
  final String? residenceId;
  final DateTime? scheduledAt;
  final String? location;
  final String? purpose;
  final String? notes;

  const HrAppointmentInput({
    required this.type,
    required this.clientId,
    this.residenceId,
    this.scheduledAt,
    this.location,
    this.purpose,
    this.notes,
  });
}
