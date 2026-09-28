import 'package:get/get.dart';

import '../profile_settings/presentation/pages/staff_profile_settings_page.dart';

/// Opens the Staff Profile & Settings screen (BUG_Report001).
///
/// Centralized so Dashboard avatar, More menu, and Quick Links all use the
/// same reliable navigation path.
Future<T?>? openStaffProfile<T>() {
  return Get.to<T>(() => const StaffProfileSettingsPage());
}
