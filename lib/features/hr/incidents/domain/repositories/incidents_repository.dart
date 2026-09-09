import 'package:gems_core/gems_core.dart';

import '../entities/incident_category_option.dart';
import '../entities/incident_cir_template_option.dart';
import '../entities/incident_client_option.dart';
import '../entities/incident_evidence_file.dart';
import '../entities/incident_residence_option.dart';
import '../entities/incident_staff_option.dart';
import '../entities/incidents_board.dart';

/// Contract for the Incidents list board and create-incident flow.
abstract class IncidentsRepository {
  Future<Result<IncidentsBoard>> getBoard();

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
