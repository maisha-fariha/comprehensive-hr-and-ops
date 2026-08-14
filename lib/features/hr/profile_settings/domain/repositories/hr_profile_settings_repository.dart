import 'package:gems_core/gems_core.dart';

import '../entities/hr_profile_settings_overview.dart';

abstract class HrProfileSettingsRepository {
  Future<Result<HrProfileSettingsOverview>> getOverview();
}
