import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/permission_gate.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../hr/attendance/domain/entities/attendance_week.dart';
import '../../../../hr/attendance/domain/entities/manual_entry_options.dart';
import '../../../../hr/attendance/domain/entities/time_off_request.dart';
import '../../domain/entities/staff_attendance_history_item.dart';
import '../../domain/entities/staff_attendance_overview.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../pages/staff_manual_attendance_entry_page.dart';
import '../widgets/staff_clock_action_sheet.dart';
import 'package:geolocator/geolocator.dart';

/// GetX controller for the "Attendance" screen.
class StaffAttendanceController
    extends BaseController<StaffAttendanceOverview> {
  final StaffAttendanceRepository repository;

  /// Live HH:MM:SS from [StaffAttendanceOverview.checkInAt].
  final RxString liveElapsedLabel = '00:00:00'.obs;

  /// Live break status (elapsed duration while on break — web parity).
  final RxString liveBreakStatusLabel = 'Not on break'.obs;

  /// Live GPS check against the residence fence (when enabled).
  final RxBool geofenceCheckBusy = false.obs;

  /// Residence options for filters + clock dialog.
  final RxList<ManualEntryResidenceOption> residenceOptions =
      <ManualEntryResidenceOption>[].obs;

  final RxList<TimeOffRequest> timeOffRequests = <TimeOffRequest>[].obs;
  final RxBool timeOffLoading = false.obs;
  final RxnString timeOffError = RxnString();
  final Rx<TimeOffStatusTab> timeOffTab = TimeOffStatusTab.all.obs;

  Timer? _ticker;

  StaffAttendanceController({required this.repository});

  StaffAttendanceOverview? get overview => state.value.data;

  @override
  void onInit() {
    super.onInit();
    loadOverview();
    _loadResidences();
    loadTimeOffRequests();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  Future<void> loadOverview() async {
    setLoading(true);
    final week = historyWeek.value;
    final residence = historyResidenceFilter.value;
    final result = await repository.getOverview(
      from: week.from,
      to: week.to,
      residenceId: residence == 'all' ? null : residence,
    );
    result.when(
      success: (overview) {
        setSuccess(overview);
        liveElapsedLabel.value = overview.elapsedTimeLabel;
        liveBreakStatusLabel.value = overview.breakStatusLabel;
        _restartTicker(overview);
        // Web: when GPS is on, resolve the device fix before offering Clock In.
        if (!overview.isOnShift && overview.requiresGeofence) {
          _refreshLiveGeofence(overview);
        }
      },
      failure: (error) {
        _ticker?.cancel();
        setError(error.message);
      },
    );
    setLoading(false);
  }

  /// Haversine check vs residence center — same rule as web clock-in gate.
  Future<void> _refreshLiveGeofence(StaffAttendanceOverview overview) async {
    geofenceCheckBusy.value = true;
    try {
      final fix = await staffClockDeviceLocation();
      final current = state.value.data;
      if (current == null || current.isOnShift) return;
      final lat = current.geofenceLatitude;
      final lng = current.geofenceLongitude;
      final radius = current.geofenceRadiusMeters;
      if (lat == null || lng == null || radius == null || radius <= 0) return;
      final distance = Geolocator.distanceBetween(
        lat,
        lng,
        fix.latitude,
        fix.longitude,
      );
      final within = distance <= radius;
      final feet = (distance * 3.28084).round();
      setSuccess(
        current.copyWith(
          isWithinGeofence: within,
          geofenceStatusLabel: within
              ? 'Within Geofence · Accuracy ${fix.accuracyMeters.round()} m'
              : 'Outside Geofence · $feet ft from center',
          geofenceAddress: [
            current.geofenceAddress.split(' · ').first,
            '${radius.round()} m radius',
            '$feet ft from center',
          ].join(' · '),
        ),
      );
    } catch (_) {
      final current = state.value.data;
      if (current == null || current.isOnShift) return;
      setSuccess(
        current.copyWith(
          isWithinGeofence: false,
          geofenceStatusLabel:
              'Location unavailable — move into the residence GPS area to clock in',
        ),
      );
    } finally {
      geofenceCheckBusy.value = false;
    }
  }

  void _restartTicker(StaffAttendanceOverview overview) {
    _ticker?.cancel();
    final checkInAt = overview.checkInAt;
    final breakStartedAt = overview.breakStartedAt;
    if (checkInAt == null && breakStartedAt == null) {
      liveElapsedLabel.value = '00:00:00';
      liveBreakStatusLabel.value = overview.breakStatusLabel;
      return;
    }
    void tick() {
      if (checkInAt != null) {
        liveElapsedLabel.value = IsoDateRange.elapsedHms(checkInAt);
      }
      if (overview.isOnBreak && breakStartedAt != null) {
        final elapsed = IsoDateRange.elapsedHms(breakStartedAt);
        liveBreakStatusLabel.value = overview.breakMinutes > 0
            ? 'On break · $elapsed · ${overview.breakMinutes}m earlier'
            : 'On break · $elapsed';
      } else {
        liveBreakStatusLabel.value = overview.breakStatusLabel;
      }
    }

    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> clockIn() => _openClockSheet(isCheckIn: true);

  Future<void> clockOut() => _openClockSheet(isCheckIn: false);

  Future<void> _openClockSheet({required bool isCheckIn}) async {
    if (residenceOptions.isEmpty) await _loadResidences();
    final context = Get.context;
    if (context == null || !context.mounted) return;
    final current = overview;
    // Without `residences:read`, GET /residences is empty — still offer the
    // home from /mobile/home (same as web clock-in with a rostered shift).
    final residences = _clockResidenceOptions(current);
    final rosteredNow = current?.hasRosteredShiftNow ?? false;

    final saved = await StaffClockActionSheet.show(
      context,
      isCheckIn: isCheckIn,
      residences: residences,
      initialResidenceId: current?.residenceId,
      // Web only posts shiftId while the shift is current. Overview may still
      // carry the next upcoming shift id for the warning copy — do not send it.
      shiftId: (!isCheckIn || rosteredNow) ? current?.shiftId : null,
      shiftEndsAt: current?.shiftEndsAt,
      showNotRosteredWarning: isCheckIn && !rosteredNow,
      nextShiftStartsAt: rosteredNow ? null : current?.shiftStartsAt,
    );
    if (saved == true) {
      Get.snackbar(
        'Attendance',
        isCheckIn ? 'Clocked in.' : 'Clocked out.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
      );
      await loadOverview();
    }
  }

  Future<void> toggleBreak() {
    final current = overview;
    if (current == null || !current.isOnShift) return Future.value();
    if (current.isOnBreak) {
      return _run(
        () => repository.endBreak(residenceId: current.residenceId),
        successMessage: 'Break ended.',
      );
    }
    return _run(
      () => repository.startBreak(residenceId: current.residenceId),
      successMessage: 'Break started.',
    );
  }

  Future<void> _run(
    Future<Result<void>> Function() action, {
    required String successMessage,
  }) async {
    setLoading(true);
    final result = await action();
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not update attendance',
      );
      return;
    }
    Get.snackbar(
      'Attendance',
      successMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
    await loadOverview();
  }

  /// History week. The web filter is Monday–Sunday, defaulting to this week.
  final Rx<AttendanceWeek> historyWeek =
      AttendanceWeek.containing(DateTime.now()).obs;

  /// `all` or a residence id.
  final RxString historyResidenceFilter = 'all'.obs;

  /// `all` | `present` | `late` | `missed` | `pending_approval`.
  final RxString historyStatusFilter = 'all'.obs;

  List<StaffAttendanceHistoryItem> get filteredHistory {
    final items = overview?.history ?? const <StaffAttendanceHistoryItem>[];
    final week = historyWeek.value;
    final residence = historyResidenceFilter.value;
    final status = historyStatusFilter.value;
    return items.where((item) {
      final at = item.occurredAt;
      if (at == null || !week.contains(at)) return false;
      if (residence != 'all' && item.residenceId != residence) return false;
      if (status != 'all') {
        final s = item.status;
        if (status == 'present') {
          if (s != 'present' &&
              s != 'on_time' &&
              s != 'ontime' &&
              s != 'completed') {
            return false;
          }
        } else if (s != status) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void setHistoryWeek(DateTime day) {
    historyWeek.value = AttendanceWeek.containing(day);
    loadOverview();
    loadTimeOffRequests();
  }

  void setHistoryResidenceFilter(String residenceId) {
    historyResidenceFilter.value = residenceId;
    loadOverview();
  }

  void setHistoryStatusFilter(String status) =>
      historyStatusFilter.value = status;

  Future<void> _loadResidences() async {
    final result = await repository.getResidences();
    result.when(
      success: (items) => residenceOptions.assignAll(items),
      failure: (_) {},
    );
  }

  List<ManualEntryResidenceOption> _clockResidenceOptions(
    StaffAttendanceOverview? current,
  ) {
    final byId = <String, ManualEntryResidenceOption>{
      for (final row in residenceOptions)
        if (row.id.isNotEmpty) row.id: row,
    };
    final id = current?.residenceId;
    final name = (current?.shiftLocationName ?? '').trim();
    if (id != null && id.isNotEmpty) {
      byId.putIfAbsent(
        id,
        () => ManualEntryResidenceOption(
          id: id,
          name: name.isEmpty ? 'Residence' : name,
        ),
      );
    }
    final session = Get.isRegistered<UserSession>()
        ? Get.find<UserSession>()
        : null;
    final sessionId = session?.residenceId;
    final sessionName = (session?.residenceName ?? '').trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      byId.putIfAbsent(
        sessionId,
        () => ManualEntryResidenceOption(
          id: sessionId,
          name: sessionName.isEmpty ? 'Residence' : sessionName,
        ),
      );
    }
    return byId.values.toList();
  }

  Future<void> showManualEntryDialog() async {
    if (Get.isRegistered<UserSession>() &&
        !Get.find<UserSession>().can('attendance:manage')) {
      return;
    }
    final saved = await Get.to<bool>(
      () => const PermissionGate(
        anyOf: ['attendance:manage'],
        title: 'Manual Entry',
        builder: StaffManualAttendanceEntryPage.new,
      ),
    );
    if (saved == true) await loadOverview();
  }

  void setTimeOffTab(TimeOffStatusTab tab) {
    if (timeOffTab.value == tab) return;
    timeOffTab.value = tab;
    loadTimeOffRequests();
  }

  Future<void> loadTimeOffRequests() async {
    timeOffLoading.value = true;
    timeOffError.value = null;
    final status = switch (timeOffTab.value) {
      TimeOffStatusTab.pending => 'pending',
      TimeOffStatusTab.approved => 'approved',
      TimeOffStatusTab.rejected => 'rejected',
      TimeOffStatusTab.all => null,
    };
    final week = historyWeek.value;
    final result = await repository.getMyTimeOffRequests(
      from: week.from,
      to: week.to,
      status: status,
    );
    result.when(
      success: (rows) {
        timeOffRequests.assignAll(rows);
        timeOffError.value = null;
      },
      failure: (error) {
        timeOffError.value = error.message;
        timeOffRequests.clear();
      },
    );
    timeOffLoading.value = false;
  }

  Future<bool> submitTimeOffRequest({
    required TimeOffType type,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    final result = await repository.createTimeOffRequest(
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );
    var ok = false;
    result.when(
      success: (_) {
        ok = true;
        AppSnackbar.show('Time off', 'Request submitted.');
      },
      failure: (error) => AppSnackbar.show('Time off', error.message),
    );
    if (ok) await loadTimeOffRequests();
    return ok;
  }

  @override
  Future<void> refresh() async {
    if (Get.isRegistered<UserSession>()) {
      await Get.find<UserSession>().refreshProfile();
    }
    await Future.wait([
      loadOverview(),
      _loadResidences(),
      loadTimeOffRequests(),
    ]);
  }
}
