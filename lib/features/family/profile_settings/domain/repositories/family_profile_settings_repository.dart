import 'package:gems_core/gems_core.dart';

import '../entities/family_profile_settings_overview.dart';

/// Contract for fetching the family member's profile, linked clients and
/// preference/settings content. The presentation layer only ever depends on
/// this interface, so swapping the mocked
/// [FamilyProfileSettingsRepositoryImpl] for a real API-backed
/// implementation later requires no changes above the data layer.
abstract class FamilyProfileSettingsRepository {
  Future<Result<FamilyProfileSettingsOverview>> getOverview();
}
