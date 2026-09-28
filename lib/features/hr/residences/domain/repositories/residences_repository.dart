import 'package:gems_core/gems_core.dart';

import '../entities/residence_summary.dart';

abstract class ResidencesRepository {
  /// Residences the manager is scoped to (`GET /residences`), with resident
  /// counts derived from `GET /clients`.
  Future<Result<List<ResidenceSummary>>> getResidences();

  /// Room board for one home (`GET /residences/{id}/rooms`).
  Future<Result<List<ResidenceRoom>>> getRooms(String residenceId);
}
