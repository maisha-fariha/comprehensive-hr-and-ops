import 'package:gems_core/gems_core.dart';

import '../entities/client_extras.dart';
import '../entities/client_goals.dart';
import '../entities/client_summary.dart';

abstract class ClientsRepository {
  /// One page of the directory (`GET /clients?page&limit&search&residenceId`).
  Future<Result<ClientPage>> getClients({
    required int page,
    required int limit,
    String? search,
    String? residenceId,
  });

  /// One resident with transfer history (`GET /clients/{id}`).
  Future<Result<ClientSummary>> getClient(String clientId);

  /// `{ residenceId: name }` for the residence pickers (`GET /residences`).
  Future<Result<Map<String, String>>> getResidenceNames();

  /// The plan's client cap from `GET /auth/me` (`null` = unlimited).
  Future<Result<int?>> getClientLimit();

  /// `POST /clients`. The same [idempotencyKey] on a retry keeps the server
  /// from creating the client twice.
  Future<Result<ClientSummary>> createClient(
    Map<String, dynamic> body, {
    String? idempotencyKey,
  });

  /// `PATCH /clients/{id}`.
  Future<Result<ClientSummary>> updateClient(
    String clientId,
    Map<String, dynamic> body,
  );

  /// `DELETE /clients/{id}` with the optional `{ reason }`.
  Future<Result<void>> deleteClient(String clientId, {String? reason});

  /// `GET /clients/deleted` (the "Deleted residents" log).
  Future<Result<List<DeletedClient>>> getDeletedClients({String? search});

  /// `POST /clients/{id}/restore`.
  Future<Result<void>> restoreClient(String clientId);

  /// `GET /client-goals/categories`.
  Future<Result<List<ClientGoalCategory>>> getGoalCategories();

  /// `GET /clients/{id}/goals?includeClosed=true`.
  Future<Result<List<ClientGoal>>> getGoals(String clientId);

  /// `POST /clients/{id}/goals` (`{ category, title?, targetDate? }`).
  Future<Result<void>> createGoal(String clientId, Map<String, dynamic> body);

  /// `PATCH /clients/{id}/goals/{goalId}` (`{ status }`).
  Future<Result<void>> updateGoal(String clientId, String goalId, Map<String, dynamic> body);

  /// `DELETE /clients/{id}/goals/{goalId}`.
  Future<Result<void>> deleteGoal(String clientId, String goalId);

  /// `GET /clients/{id}/goals/outcomes`.
  Future<Result<ClientGoalOutcomes>> getGoalOutcomes(String clientId);

  /// `POST /clients/{id}/transfer`.
  Future<Result<ClientSummary>> transferClient(
    String clientId,
    ClientTransferRequest request,
  );

  /// `GET /clients/{id}/family`.
  Future<Result<List<ClientFamilyMember>>> getFamily(String clientId);

  /// `POST /clients/{id}/family`.
  Future<Result<void>> addFamilyMember(
    String clientId,
    Map<String, dynamic> body,
  );

  /// `PATCH /clients/{id}/family/{memberId}`.
  Future<Result<void>> updateFamilyMember(
    String clientId,
    String memberId,
    Map<String, dynamic> body,
  );

  /// `DELETE /clients/{id}/family/{memberId}`.
  Future<Result<void>> removeFamilyMember(String clientId, String memberId);

  /// `GET /residences/{id}/rooms`.
  Future<Result<List<ClientRoom>>> getRooms(String residenceId);

  /// `GET /inventory/client-spend/{clientId}`.
  Future<Result<ClientSpend>> getSpend(String clientId);

  /// `POST /uploads?category=...`; returns the stored `fileUrl`.
  Future<Result<String>> uploadFile(ClientPickedFile file, String category);

  /// `POST /documents` filing an uploaded care plan on the client.
  Future<Result<void>> fileCarePlanDocument({
    required String clientId,
    required String name,
    required String fileUrl,
  });

  /// Web "Export List": `POST /reports/exports` (`client_roster`), poll,
  /// download; a roster CSV built from `GET /clients` when status or download
  /// is not allowed for this role.
  Future<Result<List<int>>> exportRosterCsv();
}
