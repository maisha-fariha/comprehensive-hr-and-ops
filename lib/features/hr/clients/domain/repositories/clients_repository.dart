import 'package:gems_core/gems_core.dart';

import '../entities/client_extras.dart';
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

  /// `POST /clients`.
  Future<Result<ClientSummary>> createClient(Map<String, dynamic> body);

  /// `PATCH /clients/{id}`.
  Future<Result<ClientSummary>> updateClient(
    String clientId,
    Map<String, dynamic> body,
  );

  /// `DELETE /clients/{id}`.
  Future<Result<void>> deleteClient(String clientId);

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
