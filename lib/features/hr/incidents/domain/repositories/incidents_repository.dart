import 'package:gems_core/gems_core.dart';

import '../entities/incident_category_option.dart';
import '../entities/incident_client_option.dart';
import '../entities/incident_residence_option.dart';
import '../entities/incidents_board.dart';

/// Contract for the Incidents list board and create-incident flow.
abstract class IncidentsRepository {
  Future<Result<IncidentsBoard>> getBoard();

  /// Categories for the Create Incident "Incident Category" dropdown.
  Future<Result<List<IncidentCategoryOption>>> getCategories();

  /// Residences for the Create Incident "Residence" dropdown.
  Future<Result<List<IncidentResidenceOption>>> getResidences();

  /// Typeahead for Create Incident "Client / Resident" via `GET /clients?search=`.
  Future<Result<List<IncidentClientOption>>> searchClients(String search);

  /// Creates an incident. Returns the new incident id when the API provides one.
  Future<Result<String>> createIncident(Map<String, dynamic> payload);
}
