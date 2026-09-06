import 'package:gems_core/gems_core.dart';

import '../entities/incidents_board.dart';

/// Contract for the Incidents list board and create-incident flow.
abstract class IncidentsRepository {
  Future<Result<IncidentsBoard>> getBoard();

  /// Creates an incident. Returns the new incident id when the API provides one.
  Future<Result<String>> createIncident(Map<String, dynamic> payload);
}
