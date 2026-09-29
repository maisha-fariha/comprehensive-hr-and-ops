import 'package:gems_core/gems_core.dart';

import '../entities/staff_daily_activity_option.dart';
import '../entities/staff_daily_activity_overview.dart';

abstract class StaffDailyActivityRepository {
  /// `GET /client-activities` with filters; summary from `meta.summary`.
  Future<Result<StaffDailyActivityOverview>> getOverview({
    int page,
    int limit,
    String? search,
    String? clientId,
    String? recordedByStaffId,
    String? activityType,
    String? status,
    DateTime? date,
  });

  Future<Result<List<StaffDailyActivityPersonOption>>> getClientOptions();

  Future<Result<List<StaffDailyActivityPersonOption>>> getStaffOptions();

  /// `POST /client-activities`.
  Future<Result<void>> recordActivity({
    required String clientId,
    required String activityDate,
    required String activityType,
    required String status,
    required String description,
    String? notes,
    String? recordedByStaffId,
    String? occurredAt,
    List<Map<String, String>>? attachments,
  });

  /// `POST /uploads?category=client-activities`.
  Future<Result<String>> uploadDocument({
    required String localPath,
    required String fileName,
  });
}
