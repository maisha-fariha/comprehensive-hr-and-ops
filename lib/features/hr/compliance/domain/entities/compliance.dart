import 'package:flutter/foundation.dart';

@immutable
class CompliancePageResult<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final Map<String, dynamic> summary;

  const CompliancePageResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    this.summary = const {},
  });
}

@immutable
class ComplianceOverview {
  final double score;
  final DateTime? computedAt;
  final Map<String, num> breakdown;
  final List<ComplianceDomainScore> domains;
  final ComplianceClientFiles clientFiles;
  final ComplianceMedication medication;
  final List<ComplianceTrendPoint> trend;
  final List<ComplianceUpcoming> upcoming;
  final List<ComplianceSourceIssue> sources;

  const ComplianceOverview({
    required this.score,
    required this.breakdown,
    required this.domains,
    required this.clientFiles,
    required this.medication,
    required this.trend,
    this.computedAt,
    this.upcoming = const [],
    this.sources = const [],
  });
}

@immutable
class ComplianceDomainScore {
  final String domain;
  final double percent;
  const ComplianceDomainScore({required this.domain, required this.percent});
}

@immutable
class ComplianceClientFiles {
  final int residents;
  final int missingCarePlan;
  final int missingRoom;
  const ComplianceClientFiles({
    this.residents = 0,
    this.missingCarePlan = 0,
    this.missingRoom = 0,
  });
}

@immutable
class ComplianceMedication {
  final int missed;
  final int refused;
  final int late;
  const ComplianceMedication({
    this.missed = 0,
    this.refused = 0,
    this.late = 0,
  });
}

@immutable
class ComplianceTrendPoint {
  final DateTime? weekStart;
  final int opened;
  const ComplianceTrendPoint({this.weekStart, this.opened = 0});
}

@immutable
class ComplianceUpcoming {
  final String id;
  final String title;
  final DateTime? dueAt;
  const ComplianceUpcoming({required this.id, required this.title, this.dueAt});
}

@immutable
class ComplianceSourceIssue {
  final String source;
  final int count;
  const ComplianceSourceIssue({required this.source, required this.count});
}

@immutable
class ComplianceAlert {
  final String id;
  final String title;
  final String? kind;
  final String? severity;
  final String? detail;

  const ComplianceAlert({
    required this.id,
    required this.title,
    this.kind,
    this.severity,
    this.detail,
  });
}

@immutable
class ComplianceRequirement {
  final String id;
  final String name;
  final String? standard;
  final String? category;
  final String frequency;
  final String? frequencyNote;
  final String priority;
  final bool evidenceRequired;
  final String? instructions;
  final bool isActive;
  final DateTime? archivedAt;

  const ComplianceRequirement({
    required this.id,
    required this.name,
    required this.frequency,
    required this.priority,
    this.standard,
    this.category,
    this.frequencyNote,
    this.evidenceRequired = false,
    this.instructions,
    this.isActive = true,
    this.archivedAt,
  });
}

@immutable
class ComplianceCheck {
  final String id;
  final String requirementId;
  final String? requirementName;
  final String? standard;
  final String? priority;
  final bool evidenceRequired;
  final String residenceId;
  final String? residenceName;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final DateTime? dueAt;
  final DateTime? checkedAt;
  final String? result;
  final String? notes;
  final String? findingId;
  final String? findingTitle;
  final String? reviewedByName;
  final DateTime? reviewedAt;

  const ComplianceCheck({
    required this.id,
    required this.requirementId,
    required this.residenceId,
    this.requirementName,
    this.standard,
    this.priority,
    this.evidenceRequired = false,
    this.residenceName,
    this.assignedStaffId,
    this.assignedStaffName,
    this.dueAt,
    this.checkedAt,
    this.result,
    this.notes,
    this.findingId,
    this.findingTitle,
    this.reviewedByName,
    this.reviewedAt,
  });
}

@immutable
class ComplianceFinding {
  final String id;
  final String title;
  final String? residenceId;
  final String? residenceName;
  final String? clientId;
  final String? clientName;
  final String? severity;
  final String? status;
  final String? framework;
  final String? issueOrigin;
  final String? riskContext;
  final String? notes;
  final String? sourceRecordType;
  final String? sourceRecordId;
  final DateTime? dueAt;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final String? assigneeName;

  const ComplianceFinding({
    required this.id,
    required this.title,
    this.residenceId,
    this.residenceName,
    this.clientId,
    this.clientName,
    this.severity,
    this.status,
    this.framework,
    this.issueOrigin,
    this.riskContext,
    this.notes,
    this.sourceRecordType,
    this.sourceRecordId,
    this.dueAt,
    this.resolvedAt,
    this.createdAt,
    this.assigneeName,
  });
}

@immutable
class ComplianceAction {
  final String id;
  final String description;
  final String? incidentId;
  final String? findingTitle;
  final String? ownerId;
  final String? ownerName;
  final String? status;
  final DateTime? dueAt;
  final DateTime? verifiedAt;
  final String? verifiedByName;

  const ComplianceAction({
    required this.id,
    required this.description,
    this.incidentId,
    this.findingTitle,
    this.ownerId,
    this.ownerName,
    this.status,
    this.dueAt,
    this.verifiedAt,
    this.verifiedByName,
  });
}

@immutable
class ComplianceAuditLog {
  final String id;
  final String action;
  final String? actorName;
  final String? module;
  final String? entityType;
  final String? entityId;
  final String? outcome;
  final DateTime? createdAt;

  const ComplianceAuditLog({
    required this.id,
    required this.action,
    this.actorName,
    this.module,
    this.entityType,
    this.entityId,
    this.outcome,
    this.createdAt,
  });
}

@immutable
class CompliancePersonOption {
  final String id;
  final String name;
  const CompliancePersonOption({required this.id, required this.name});
}

@immutable
class ComplianceExportJob {
  final String id;
  final String reportKey;
  final String status;
  final DateTime? createdAt;
  final String? downloadUrl;

  const ComplianceExportJob({
    required this.id,
    required this.reportKey,
    required this.status,
    this.createdAt,
    this.downloadUrl,
  });
}
