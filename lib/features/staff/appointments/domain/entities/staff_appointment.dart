import 'package:flutter/foundation.dart';

enum StaffAppointmentTab {
  pending,
  approved,
  familyVisits,
  external,
  rejected,
  all,
}

@immutable
class StaffAppointment {
  final String id;
  final String type;
  final String status;
  final String clientId;
  final String clientName;
  final String? residenceId;
  final String residenceName;
  final String requesterName;
  final String? requesterRelationship;
  final DateTime? scheduledAt;
  final String? location;
  final String? purpose;
  final String? notes;
  final String? deciderName;
  final DateTime? decidedAt;
  final String? decisionReason;

  const StaffAppointment({
    required this.id,
    required this.type,
    required this.status,
    this.clientId = '',
    this.clientName = 'Resident',
    this.residenceId,
    this.residenceName = '',
    this.requesterName = '',
    this.requesterRelationship,
    this.scheduledAt,
    this.location,
    this.purpose,
    this.notes,
    this.deciderName,
    this.decidedAt,
    this.decisionReason,
  });

  bool get isPending => normalizedStatus == 'pending';
  bool get isFamilyVisit => type == 'family_visit';
  bool get isExternal => type == 'external';
  bool get isRejected => normalizedStatus == 'rejected';
  bool get isCancelled => normalizedStatus == 'cancelled';
  bool get canRestore => isRejected || isCancelled;

  /// API may return `confirmed` for staff-created external appointments.
  String get normalizedStatus {
    if (status == 'confirmed') return 'approved';
    return status;
  }

  String get shortId {
    final raw = id.replaceAll('-', '');
    final slice = raw.length >= 8 ? raw.substring(0, 8) : raw;
    return 'APT-${slice.toLowerCase()}';
  }

  String get typeLabel {
    switch (type) {
      case 'family_visit':
        return 'Family visit';
      case 'external':
        return 'External';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String get statusLabel {
    switch (normalizedStatus) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return status == 'confirmed' ? 'Confirmed' : 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  String get dateTimeLabel {
    final at = scheduledAt;
    if (at == null) return '—';
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year} · $h:$min';
  }

  String get decidedAtLabel {
    final at = decidedAt;
    if (at == null) return '';
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  String get requesterLabel {
    if (requesterName.isEmpty) return '—';
    final rel = requesterRelationship?.trim();
    if (rel == null || rel.isEmpty) return requesterName;
    return '$requesterName ($rel)';
  }
}

@immutable
class StaffAppointmentsSummary {
  final int pending;
  final int approved;
  final int rejected;
  final int cancelled;
  final int completed;
  final int approvedToday;
  final int upcomingVisits;
  final int upcomingExternal;
  final int total;

  const StaffAppointmentsSummary({
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

@immutable
class StaffAppointmentsPageResult {
  final List<StaffAppointment> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const StaffAppointmentsPageResult({
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });
}

@immutable
class StaffAppointmentClientOption {
  final String id;
  final String label;
  final String? residenceId;
  final String residenceName;

  const StaffAppointmentClientOption({
    required this.id,
    required this.label,
    this.residenceId,
    this.residenceName = '',
  });
}

@immutable
class StaffCreateAppointmentInput {
  final String type;
  final String clientId;
  final DateTime scheduledAt;
  final String? purpose;
  final String? notes;
  final String? location;
  final String? residenceId;

  const StaffCreateAppointmentInput({
    required this.type,
    required this.clientId,
    required this.scheduledAt,
    this.purpose,
    this.notes,
    this.location,
    this.residenceId,
  });
}

@immutable
class StaffUpdateAppointmentInput {
  final DateTime? scheduledAt;
  final String? purpose;
  final String? notes;
  final String? location;
  final String? clientId;
  final String? residenceId;

  const StaffUpdateAppointmentInput({
    this.scheduledAt,
    this.purpose,
    this.notes,
    this.location,
    this.clientId,
    this.residenceId,
  });
}
