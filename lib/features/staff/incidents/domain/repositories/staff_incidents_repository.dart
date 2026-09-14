import 'package:gems_core/gems_core.dart';

import '../entities/incident_detail.dart';
import '../entities/staff_incident.dart';
import '../entities/staff_incident_options.dart';
import '../entities/staff_incidents_summary.dart';

/// Contract for Staff Incidents list, detail, and create flows.
abstract class StaffIncidentsRepository {
  /// `GET /incidents` — My Incidents uses `reporter=me`.
  Future<Result<List<StaffIncident>>> getIncidents({
    bool mine = false,
    String? search,
    String? severity,
    String? status,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  });

  /// `GET /incidents/summary` — header / tab counter.
  Future<Result<StaffIncidentsSummary>> getSummary();

  Future<Result<IncidentDetail>> getIncidentDetail(String incidentId);

  Future<Result<void>> acknowledge(String incidentId);

  Future<Result<void>> addInvestigationNote({
    required String incidentId,
    required String notes,
  });

  /// `GET /incident-categories`
  Future<Result<List<StaffIncidentCategoryOption>>> getCategories();

  /// `GET /incidents/cir-templates`
  Future<Result<List<StaffCirTemplateOption>>> getCirTemplates();

  /// `GET /clients?assignedToMe=true` or `?search=`
  Future<Result<List<StaffIncidentClientOption>>> getClients({
    String? search,
    bool assignedToMe = true,
  });

  /// `POST /incidents` — always `status: open` (no draft).
  Future<Result<String>> createIncident({
    required String residenceId,
    required String clientId,
    required String categoryId,
    required String title,
    required String severity,
    required Map<String, dynamic> payload,
    String? cirTemplateId,
    String? occurredAt,
    String? description,
    String? location,
    bool? residentChecked,
    bool? supervisorNotified,
    bool? familyNotified,
    bool? carePlanReviewed,
  });

  /// `PATCH /incidents/{incidentId}` — edit later; omit unchanged checklist.
  Future<Result<void>> updateIncident({
    required String incidentId,
    required String residenceId,
    required String clientId,
    required String categoryId,
    required String title,
    required String severity,
    required Map<String, dynamic> payload,
    String? cirTemplateId,
    String? occurredAt,
    String? description,
    String? location,
    bool? residentChecked,
    bool? supervisorNotified,
    bool? familyNotified,
    bool? carePlanReviewed,
  });

  /// `POST /uploads?category=incidents`
  Future<Result<StaffIncidentEvidenceFile>> uploadEvidenceFile(
    StaffIncidentEvidenceFile file,
  );

  /// `POST /incidents/{incidentId}/evidence`
  Future<Result<void>> attachEvidence({
    required String incidentId,
    required String fileUrl,
    required String fileType,
  });
}
