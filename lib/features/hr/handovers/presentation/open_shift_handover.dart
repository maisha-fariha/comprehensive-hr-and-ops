import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../core/roles/user_role.dart';
import '../../../staff/extras/presentation/pages/staff_shift_handovers_page.dart';
import 'pages/handovers_page.dart';

/// Web clock-out toast: "Write it" opens `/dashboard/handovers` for the shift.
Future<void> openShiftHandover({
  required UserRole role,
  String? shiftId,
  String? residenceId,
}) {
  final staff = role == UserRole.staff;
  final shift = shiftId?.trim();
  final residence = residenceId?.trim();
  return Get.to<void>(
        () => staff
            ? StaffShiftHandoversPage(
                focusShiftId: shift,
                focusResidenceId: residence,
              )
            : HandoversPage(
                focusShiftId: shift,
                focusResidenceId: residence,
              ),
      ) ??
      Future<void>.value();
}

bool handoverRequired(AppError? error) {
  final data = error is ApiError ? error.responseData : null;
  final nested = data?['error'];
  final code =
      '${data?['code'] ?? data?['errorCode'] ?? (nested is Map ? nested['code'] : '') ?? ''}'
          .toUpperCase();
  if (code == 'HANDOVER_REQUIRED') return true;
  return (error?.message ?? '').toLowerCase().contains('handover');
}

String? handoverShiftIdOf(AppError? error) {
  final data = error is ApiError ? error.responseData : null;
  if (data == null) return null;
  final details = data['details'] ??
      (data['error'] is Map ? (data['error'] as Map)['details'] : null);
  if (details is Map) {
    final id = details['shiftId']?.toString();
    if (id != null && id.isNotEmpty) return id;
  }
  return null;
}
