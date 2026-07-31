import 'package:gems_core/gems_core.dart';

import '../entities/incidents_board.dart';

/// Contract for fetching the Incidents list content (all 3 tabs). The
/// presentation layer only ever depends on this interface, so swapping the
/// mocked [IncidentsRepositoryImpl] for a real API-backed implementation
/// later requires no changes above the data layer.
abstract class IncidentsRepository {
  Future<Result<IncidentsBoard>> getBoard();
}
