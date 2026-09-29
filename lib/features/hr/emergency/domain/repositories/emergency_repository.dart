import 'package:gems_core/gems_core.dart';

import '../entities/emergency_alert.dart';

abstract class EmergencyRepository {
  /// `GET /emergency-alerts` - [status] null lists every status.
  Future<Result<EmergencyAlertPage>> list({
    String? status,
    required int page,
    required int limit,
  });

  Future<Result<EmergencyAlert>> byId(String id);

  Future<Result<void>> raise({
    required String residenceId,
    required String type,
    String? note,
    String? locationNote,
    double? latitude,
    double? longitude,
  });

  Future<Result<void>> acknowledge(String id);

  Future<Result<void>> resolve(String id);

  Future<Result<void>> assign(String id, String userId);

  /// `acknowledged` or `in_progress`.
  Future<Result<void>> setStatus(String id, String status);

  Future<Result<void>> addNote(String id, String note);

  Future<Result<void>> delete(String id);

  Future<Result<List<EmergencyOption>>> residences();
}
