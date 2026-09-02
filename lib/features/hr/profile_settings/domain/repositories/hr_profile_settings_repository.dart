import 'package:gems_core/gems_core.dart';

import '../entities/hr_profile_settings_overview.dart';

abstract class HrProfileSettingsRepository {
  Future<Result<HrProfileSettingsOverview>> getOverview();

  Future<Result<void>> createSupportTicket({
    required String subject,
    required String body,
  });

  Future<Result<Map<String, bool>>> getNotificationPreferences();

  Future<Result<void>> updateNotificationPreferences(Map<String, bool> values);

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
