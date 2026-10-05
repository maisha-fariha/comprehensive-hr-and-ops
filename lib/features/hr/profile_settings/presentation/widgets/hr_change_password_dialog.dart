import 'package:flutter/material.dart';

import '../../../../../core/widgets/change_password_dialog.dart';
import '../controllers/hr_profile_settings_controller.dart';

/// Current / new / confirm password dialog → `POST /auth/change-password`.
Future<void> showHrChangePasswordDialog(
  BuildContext context,
  HrProfileSettingsController controller,
) async {
  await showChangePasswordDialog(
    context,
    onSubmit: controller.changePassword,
  );
}
