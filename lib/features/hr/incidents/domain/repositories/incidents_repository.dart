import 'package:gems_core/gems_core.dart';

import '../entities/incident_category_option.dart';
import '../entities/incident_cir_template_option.dart';
import '../entities/incident_client_option.dart';
import '../entities/incident_evidence_file.dart';
import '../entities/incident_investigation_summary.dart';
import '../entities/incident_residence_option.dart';
import '../entities/incident_staff_option.dart';
import '../entities/incidents_board.dart';

/// Contract for the Incidents list board and create-incident flow.
abstract class IncidentsRepository {
  Future<Result<IncidentsBoard>> getBoard();

  /// Investigation summary for Under Review → View Investigation.
  ///
  /// Loads `GET /incidents/:id` (per-incident detail). Board counters still
  /// use `GET /incidents/summary`.
  Future<Result<IncidentInvestigationSummary>> getInvestigationSummary(
    String incidentId,
  );

  /// Signed CIR PDF URL (`GET /incidents/:id/cir-pdf-link`).
  Future<Result<String>> getCirPdfLink(String incidentId);

  /// CIR PDF bytes for print / download (`cir-pdf-link` then PDF fetch).
  Future<Result<List<int>>> downloadCirPdf(String incidentId);

  /// Full incident detail (`GET /incidents/:id`) for edit-mode prefill.
  Future<Result<Map<String, dynamic>>> getIncidentDetail(String incidentId);

  /// Categories for the Create Incident "Incident Category" dropdown.
  Future<Result<List<IncidentCategoryOption>>> getCategories();

  /// CIR templates for Create Incident (`GET /incidents/cir-templates`).
  Future<Result<List<IncidentCirTemplateOption>>> getCirTemplates();

  /// Residences for the Create Incident "Residence" dropdown.
  Future<Result<List<IncidentResidenceOption>>> getResidences();

  /// Staff for people / reporter / supervisor pickers (`GET /staff`).
  Future<Result<List<IncidentStaffOption>>> getStaff();

  /// Typeahead for Create Incident "Client / Resident" via `GET /clients?search=`.
  Future<Result<List<IncidentClientOption>>> searchClients(String search);

  /// Creates an incident (`POST /incidents`). Returns the new incident id.
  Future<Result<String>> createIncident({
    required String residenceId,
    required String clientId,
    required String categoryId,
    required String title,
    required String severity,
    required Map<String, dynamic> payload,
    String? cirTemplateId,
    String status = 'open',
    String? reportedAt,
    bool residentChecked = false,
    bool supervisorNotified = false,
    bool familyNotified = false,
    bool carePlanReviewed = false,
  });

  /// Updates an existing incident (`PATCH /incidents/:id`).
  Future<Result<void>> updateIncident({
    required String incidentId,
    required String residenceId,
    required String clientId,
    required String categoryId,
    required String title,
    required String severity,
    required Map<String, dynamic> payload,
    String? cirTemplateId,
    String? status,
    String? reportedAt,
    bool residentChecked = false,
    bool supervisorNotified = false,
    bool familyNotified = false,
    bool carePlanReviewed = false,
  });

  /// Upload a local file (`POST /uploads?category=documents`).
  Future<Result<IncidentEvidenceFile>> uploadEvidenceFile(
    IncidentEvidenceFile file,
  );

  /// Attach uploaded evidence (`POST /incidents/:id/evidence`).
  Future<Result<void>> attachEvidence({
    required String incidentId,
    required String fileUrl,
    required String fileType,
  });

  /// Record investigation notes (`PATCH /incidents/:id/investigation`).
  Future<Result<void>> recordInvestigation({
    required String incidentId,
    required String findings,
    String? rootCause,
    String? correctiveActions,
    String status = 'open',
  });
}
