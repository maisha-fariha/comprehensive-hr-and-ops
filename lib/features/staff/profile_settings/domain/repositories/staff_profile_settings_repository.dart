import 'package:gems_core/gems_core.dart';

import '../entities/staff_profile_settings_overview.dart';

abstract class StaffProfileSettingsRepository {
  Future<Result<StaffProfileSettingsOverview>> getOverview();
}
