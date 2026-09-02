import 'package:gems_core/gems_core.dart';

import '../entities/family_profile_settings_overview.dart';

abstract class FamilyProfileSettingsRepository {
  Future<Result<FamilyProfileSettingsOverview>> getOverview();

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
