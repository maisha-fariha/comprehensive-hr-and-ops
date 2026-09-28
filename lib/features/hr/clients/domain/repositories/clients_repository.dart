import 'package:gems_core/gems_core.dart';

import '../entities/client_summary.dart';

abstract class ClientsRepository {
  /// Residents in the manager's scope (`GET /clients`).
  Future<Result<List<ClientSummary>>> getClients();

  /// One resident with transfer history (`GET /clients/{id}`).
  Future<Result<ClientSummary>> getClient(String clientId);

  /// `{ residenceId: name }` for the residence filter (`GET /residences`).
  Future<Result<Map<String, String>>> getResidenceNames();
}
