import 'package:gems_core/gems_core.dart';

import '../entities/handover_options.dart';
import '../entities/shift_handover.dart';

/// Web `/dashboard/handovers` reads and writes.
abstract class HandoversRepository {
  /// `GET /shift-handovers?page=1&limit=20` with the page filters.
  Future<Result<List<ShiftHandover>>> list({
    String? status,
    String? staffId,
    String? residenceId,
    String? from,
    String? to,
  });

  Future<Result<ShiftHandover>> byId(String id);

  /// `POST /shift-handovers`; returns who it was announced to.
  Future<Result<HandoverAnnouncement?>> create(Map<String, dynamic> body);

  Future<Result<void>> setStatus(String id, String status);

  Future<Result<void>> comment(String id, String body);

  Future<Result<void>> acknowledge(String id, {String? note});

  Future<Result<void>> delete(String id);

  Future<Result<List<HandoverOption>>> residences();

  Future<Result<List<HandoverOption>>> staff();

  Future<Result<List<HandoverOption>>> clients(String residenceId);

  /// The caller's own shifts from the last day that they clocked in to.
  Future<Result<List<HandoverShift>>> myRecentShifts(String staffId);

  /// The residence's shifts from the last day, newest first.
  Future<Result<List<HandoverShift>>> residenceRecentShifts(String residenceId);

  /// Up to ten shifts starting at or after [after] (now when null).
  Future<Result<List<HandoverShift>>> incomingShifts(
    String residenceId,
    DateTime? after,
  );
}
