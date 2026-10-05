import 'dart:async';

import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../features/family/dashboard/domain/repositories/family_dashboard_repository.dart';
import '../../features/hr/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/staff/attendance/domain/repositories/staff_attendance_repository.dart';
import '../../features/staff/daily_logs/domain/repositories/staff_daily_logs_repository.dart';
import '../../features/staff/dashboard/domain/repositories/staff_dashboard_repository.dart';
import '../../features/staff/extras/domain/repositories/staff_extras_repository.dart';
import '../../features/staff/incidents/domain/repositories/staff_incidents_repository.dart';
import '../../features/staff/medication/domain/repositories/staff_medication_repository.dart';
import '../../features/staff/profile_settings/domain/repositories/staff_profile_settings_repository.dart';
import '../../features/staff/scheduling/domain/repositories/staff_schedule_repository.dart';
import '../../features/staff/tasks_messages/domain/repositories/staff_tasks_messages_repository.dart';
import '../network/connectivity_monitor.dart';
import '../network/iso_date_range.dart';
import '../roles/user_role.dart';
import '../roles/user_session.dart';
import 'offline_config.dart';
import 'outbox_context.dart';

/// Fills the read cache with what people need on shift, using the same
/// repository calls (and therefore cache keys) as the screens: first the
/// main lists, then the details, pickers and threads those lists link to,
/// so opening them later without a connection still works.
/// Silent, throttled, sequential, capped, and skipped while offline.
abstract final class OfflinePrewarmer {
  static DateTime? _lastRun;
  static Timer? _pending;
  static bool _running = false;

  /// Upper bound on per-item detail requests per list.
  static const int detailCap = 25;

  static void schedule({Duration delay = const Duration(seconds: 3)}) {
    _pending?.cancel();
    _pending = Timer(delay, () => unawaited(run()));
  }

  static Future<void> run({bool force = false}) async {
    if (_running) return;
    final last = _lastRun;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < OfflineConfig.prewarmThrottle) {
      return;
    }
    if (!Get.isRegistered<UserSession>()) return;
    final session = Get.find<UserSession>();
    if (!_canRun(session)) return;

    _running = true;
    _lastRun = DateTime.now();
    try {
      await OutboxContext.run(() async {
        final details = <Future<void> Function()>[];
        await _runAll(session, _screensFor(session, details));
        await _runAll(session, details);
      }, silent: true);
    } finally {
      _running = false;
    }
  }

  static bool _canRun(UserSession session) {
    if (!session.isSignedIn || session.isSigningOut) return false;
    if (Get.isRegistered<ConnectivityMonitor>() &&
        !Get.find<ConnectivityMonitor>().online) {
      return false;
    }
    return true;
  }

  static Future<void> _runAll(
    UserSession session,
    List<Future<void> Function()> tasks,
  ) async {
    for (final task in tasks) {
      if (!_canRun(session)) break;
      try {
        await task();
      } catch (_) {}
    }
  }

  /// Main screens. Each may queue follow-up detail work into [details].
  static List<Future<void> Function()> _screensFor(
    UserSession session,
    List<Future<void> Function()> details,
  ) {
    final getIt = GetIt.instance;
    T? find<T extends Object>() => getIt.isRegistered<T>() ? getIt<T>() : null;
    final tasks = <Future<void> Function()>[];
    final now = DateTime.now();

    switch (session.role) {
      case UserRole.staff:
        final dashboard = find<StaffDashboardRepository>();
        if (dashboard != null) tasks.add(() => dashboard.getOverview());

        final schedule = find<StaffScheduleRepository>();
        if (schedule != null) {
          tasks.add(() async {
            final result = await schedule.getOverview(
              weekStart: IsoDateRange.startOfWeek(now),
              selectedDate: DateTime(now.year, now.month, now.day),
            );
            final shifts = result.value?.shifts ?? const [];
            for (final shift in shifts.take(detailCap)) {
              details.add(() => schedule.getShiftDetail(shift.id));
            }
          });
          details.add(() => schedule.getResidences());
        }

        final mar = find<StaffMedicationRepository>();
        if (mar != null && session.canAccessMar) {
          tasks.add(() => mar.getOverview());
          tasks.add(() async {
            final clients = await mar.getClients();
            await mar.listPrnMedications();
            await mar.listAdministrations();
            await mar.listMedications();
            await mar.getResidences();
            for (final client in (clients.value ?? const []).take(60)) {
              details.add(() => mar.getClientMedications(client.id));
              details.add(() => mar.getClientPrnMedications(client.id));
            }
          });
          details.add(() => mar.getCheckSchedules());
        }

        final tasksRepo = find<StaffTasksMessagesRepository>();
        if (tasksRepo != null && session.canAccessTasks) {
          tasks.add(() async {
            final result = await tasksRepo.getOverview();
            final overview = result.value;
            if (overview == null) return;
            for (final task in overview.tasks.take(detailCap)) {
              details.add(() => tasksRepo.getTaskDetail(task.id));
            }
            for (final c in overview.conversations.take(detailCap)) {
              details.add(() => tasksRepo.getThread(
                    conversationId: c.id,
                    contactName: c.name,
                  ));
            }
          });
          details.add(() => tasksRepo.getContacts());
          details.add(() => tasksRepo.getTaskCreationOptions());
          final residenceId = session.residenceId;
          if (residenceId != null && residenceId.isNotEmpty) {
            details.add(() => tasksRepo.getTaskShifts(residenceId));
            details.add(() => tasksRepo.getTaskRooms(residenceId));
            details.add(() => tasksRepo.getTaskClients(residenceId));
          }
          details.add(() => tasksRepo.getRecurringCheckSchedules());
          details.add(() {
            final start = IsoDateRange.startOfLocalDay(now);
            return tasksRepo.getRecurringCheckInstances(
              from: start,
              to: start.add(const Duration(days: 1)),
              status: 'all',
              residenceId: 'all',
            );
          });
        }

        final attendance = find<StaffAttendanceRepository>();
        if (attendance != null) {
          tasks.add(() => attendance.getOverview());
          details.add(() => attendance.getResidences());
          details.add(() => attendance.getRosteredShifts(
                residenceId: session.residenceId,
                around: now,
              ));
        }

        final logs = find<StaffDailyLogsRepository>();
        if (logs != null && session.canAccessDailyLogs) {
          tasks.add(() async {
            final options = await logs.getResidenceOptions();
            final list = options.value ?? const [];
            final sessionResidence = session.residenceId;
            final residenceId = sessionResidence != null &&
                    list.any((r) => r.id == sessionResidence)
                ? sessionResidence
                : (list.isEmpty ? null : list.first.id);
            if (residenceId == null) return;
            final overview = await logs.getOverview(
              residenceId: residenceId,
              from: now.subtract(const Duration(days: 6)),
              to: now,
            );
            final entries = [
              ...?overview.value?.toReview,
              ...?overview.value?.missing,
            ];
            final ids = <String>{
              for (final e in entries)
                if (e.entryId != null && e.entryId!.isNotEmpty) e.entryId!,
            };
            for (final id in ids.take(detailCap)) {
              details.add(() => logs.getEntryDetail(id));
            }
          });
          details.add(() => logs.getEmptyDailyNote());
        }

        final incidents = find<StaffIncidentsRepository>();
        if (incidents != null && session.canAccessIncidents) {
          tasks.add(() async {
            await incidents.getSummary();
            final list = await incidents.getIncidents(search: '', limit: 50);
            for (final incident in (list.value ?? const []).take(detailCap)) {
              details.add(() => incidents.getIncidentDetail(incident.id));
            }
          });
          details.add(() => incidents.getCategories());
          details.add(() => incidents.getCirTemplates());
          details.add(() => incidents.getResidences());
          details.add(() => incidents.getClients(assignedToMe: true));
          details.add(() => incidents.getClients(assignedToMe: false));
          details.add(() => incidents.getStaffOptions());
        }

        final extras = find<StaffExtrasRepository>();
        if (extras != null && session.canAccessHandovers) {
          details.add(() => extras.getHandovers(
                status: 'all',
                authorId: 'all',
                residenceId: 'all',
              ));
        }
        if (extras != null) details.add(() => extras.getResidences());

        final profile = find<StaffProfileSettingsRepository>();
        if (profile != null) details.add(() => profile.getOverview());
      case UserRole.hr:
        final dashboard = find<DashboardRepository>();
        if (dashboard != null) tasks.add(() => dashboard.getOverview());
      case UserRole.family:
        final dashboard = find<FamilyDashboardRepository>();
        if (dashboard != null) tasks.add(() => dashboard.getOverview());
    }
    return tasks;
  }
}
