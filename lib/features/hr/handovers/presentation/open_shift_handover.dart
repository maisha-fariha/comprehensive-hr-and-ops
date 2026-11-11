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
  if (error == null) return false;
  final code = _handoverErrorCode(error);
  if (code == 'HANDOVER_REQUIRED') return true;
  // Location / geofence failures must not match a loose "handover" substring.
  // Only the known clock-out copy from older servers without a code.
  final message = error.message.trim().toLowerCase();
  return message.contains('write the handover') ||
      message.contains('handover for this shift before clocking');
}

String? _handoverErrorCode(AppError? error) {
  if (error is ApiError) {
    final data = error.responseData;
    final nested = data?['error'];
    final fromBody =
        '${data?['code'] ?? data?['errorCode'] ?? (nested is Map ? nested['code'] : '') ?? ''}';
    if (fromBody.trim().isNotEmpty) return fromBody.trim().toUpperCase();
  }
  if (error is ValidationError) {
    final codes = error.fieldErrors?['code'];
    if (codes != null && codes.isNotEmpty) {
      return codes.first.trim().toUpperCase();
    }
  }
  // Prefer symbolic codes over numeric HTTP status strings ("409").
  final symbolic = error?.code?.trim().toUpperCase();
  if (symbolic != null &&
      symbolic.isNotEmpty &&
      int.tryParse(symbolic) == null) {
    return symbolic;
  }
  return null;
}

String? handoverShiftIdOf(AppError? error) {
  if (error is ApiError) {
    final data = error.responseData;
    if (data != null) {
      final details = data['details'] ??
          (data['error'] is Map ? (data['error'] as Map)['details'] : null);
      if (details is Map) {
        final id = details['shiftId']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
    }
  }
  if (error is ValidationError) {
    final ids = error.fieldErrors?['shiftId'] ??
        error.fieldErrors?['details.shiftId'];
    if (ids != null && ids.isNotEmpty && ids.first.trim().isNotEmpty) {
      return ids.first.trim();
    }
  }
  return null;
}
