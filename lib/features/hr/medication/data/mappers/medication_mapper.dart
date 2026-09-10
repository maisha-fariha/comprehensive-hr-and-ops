import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/client_medication_item.dart';
import '../../domain/entities/medication_alert.dart';
import '../../domain/entities/medication_dose.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/medication_overview.dart';
import '../../domain/entities/medication_stat_tile_data.dart';
import '../../domain/entities/missed_medication.dart';
import '../../domain/entities/refused_medication.dart';
import '../../domain/entities/schedule_dose.dart';

abstract final class MedicationMapper {
  static MedicationOverview compose({
    required dynamic dueBody,
    required dynamic roundBody,
    required dynamic missedBody,
    required dynamic refusedBody,
    required dynamic seriesBody,
    required String? residenceName,
  }) {
    final dueRows = _expandDueRows(_rows(dueBody, extraKey: 'occurrences'));
    // /mar/round is fetched for Due-tab Morning/Afternoon/Evening context.
    // When round returns occurrence hours/status, merge onto due rows for richer grouping.
    final roundRows = _expandDueRows(_rows(roundBody, extraKey: 'occurrences'));
    final scheduleRows =
        _mergeRoundOntoDue(dueRows: dueRows, roundRows: roundRows);
    final missedRows = _rows(missedBody);
    final refusedRows = _rows(refusedBody);
    final compliance = _complianceLabel(seriesBody);

    // Priority / Later / Completed — GET /mar/due response, split by time.
    final grouped = _groupDueByTime(scheduleRows);
    final priority = grouped.priority;
    final later = grouped.later;
    final completed = grouped.completed;

    final uniqueDue =
        priority.isNotEmpty ? priority.length : scheduleRows.length;
    final overviewDoses = scheduleRows.map(_overviewDose).toList();

    return MedicationOverview(
      screenTitle: 'Medication MAR',
      screenSubtitle:
          residenceName == null ? 'Oversight' : 'Oversight · $residenceName',
      dueCount: uniqueDue,
      missedCount: missedRows.length,
      refusedCount: refusedRows.length,
      overviewStats: [
        MedicationStatTileData(
          id: 'compliance',
          tag: MedicationStatTag.compliance,
          value: compliance,
          label: 'Compliance',
        ),
        MedicationStatTileData(
          id: 'due-today',
          tag: MedicationStatTag.dueToday,
          value: '$uniqueDue',
          label: 'Due Today',
        ),
        MedicationStatTileData(
          id: 'missed',
          tag: MedicationStatTag.missedCount,
          value: '${missedRows.length}',
          label: 'Missed',
        ),
        MedicationStatTileData(
          id: 'refused',
          tag: MedicationStatTag.refusedCount,
          value: '${refusedRows.length}',
          label: 'Refused',
        ),
      ],
      dueTodayDoses: overviewDoses.take(5).toList(),
      moreDueTodayCount:
          (overviewDoses.length - 5).clamp(0, overviewDoses.length),
      missedRefusedAlerts: [
        ...missedRows.map((row) => _alert(row, AlertKind.missed)),
        ...refusedRows.map((row) => _alert(row, AlertKind.refused)),
      ],
      scheduleTitle: "Today's Medication Schedule",
      scheduleSubtitle:
          '${priority.length} priority · ${later.length} later · ${completed.length} completed',
      // Priority / Later / Completed from GET /mar/due (split by time).
      // Morning/Afternoon/Evening chips filter these by hour (/mar/round loaded for round context).
      priorityDoses: priority,
      laterTodayDoses: later,
      completedDoses: completed,
      missedStats: [
        MedicationStatTileData(
          id: 'missed-today',
          tag: MedicationStatTag.missedToday,
          value: '${missedRows.length}',
          label: 'Missed Today',
        ),
        MedicationStatTileData(
          id: 'critical-missed',
          tag: MedicationStatTag.criticalMissed,
          value:
              '${missedRows.where((row) => JsonCodec.boolean(row['isCritical'] ?? row['critical']) ?? false).length}',
          label: 'Critical',
        ),
      ],
      missedMedications: missedRows.map(_missed).toList(),
      refusedStats: [
        MedicationStatTileData(
          id: 'total-refused',
          tag: MedicationStatTag.totalRefused,
          value: '${refusedRows.length}',
          label: 'Total Refused',
        ),
        MedicationStatTileData(
          id: 'needs-follow-up',
          tag: MedicationStatTag.needsFollowUp,
          value:
              '${refusedRows.where((row) => JsonCodec.boolean(row['needsFollowUp'] ?? row['followUp']) ?? true).length}',
          label: 'Needs Follow Up',
        ),
      ],
      refusedMedications: refusedRows.map(_refused).toList(),
    );
  }

  /// Split GET /mar/due rows into Priority / Later / Completed by status + clock.
  static ({
    List<ScheduleDose> priority,
    List<ScheduleDose> later,
    List<ScheduleDose> completed,
  }) _groupDueByTime(List<Map<String, dynamic>> rows) {
    final priority = <ScheduleDose>[];
    final later = <ScheduleDose>[];
    final completed = <ScheduleDose>[];
    final now = DateTime.now();

    for (final row in rows) {
      final state = (JsonCodec.string(row['state'] ?? row['status']) ?? '')
          .toLowerCase();
      if (state == 'given' ||
          state == 'administered' ||
          state == 'completed' ||
          state == 'taken') {
        completed.add(_schedule(row, DoseStatus.completed));
        continue;
      }
      if (state == 'missed' || state == 'refused' || state == 'skipped') {
        continue;
      }
      if (state == 'upcoming' || state == 'scheduled') {
        later.add(_schedule(row, DoseStatus.upcoming));
        continue;
      }
      if (state == 'late' || state == 'overdue' || state == 'due_soon') {
        priority.add(_schedule(row, DoseStatus.dueSoon));
        continue;
      }

      final minutes = _minutesUntilTodayDose(row, now);
      if (minutes == null) {
        priority.add(_schedule(row, DoseStatus.due));
        continue;
      }
      if (minutes < -5) {
        // Past dose without an administered status → still show as priority.
        priority.add(_schedule(row, DoseStatus.dueSoon));
      } else if (minutes <= 30) {
        priority.add(_schedule(row, DoseStatus.dueSoon));
      } else {
        later.add(_schedule(row, DoseStatus.upcoming));
      }
    }

    return (priority: priority, later: later, completed: completed);
  }

  static int? _minutesUntilTodayDose(
    Map<String, dynamic> row,
    DateTime now,
  ) {
    final scheduled = JsonCodec.dateTime(
      row['scheduledAt'] ?? row['dueAt'] ?? row['time'],
    );
    if (scheduled != null) {
      final local = scheduled.toLocal();
      final at = DateTime(now.year, now.month, now.day, local.hour, local.minute);
      return at.difference(now).inMinutes;
    }
    final label = JsonCodec.string(row['timeLabel']);
    if (label == null || label.trim().isEmpty) return null;
    final parts = label.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final at = DateTime(now.year, now.month, now.day, hour, minute);
    return at.difference(now).inMinutes;
  }

  /// Flatten `schedule.times` from GET /mar/due into one row per dose time.
  static List<Map<String, dynamic>> _expandDueRows(
    List<Map<String, dynamic>> rows,
  ) {
    final expanded = <Map<String, dynamic>>[];
    for (final row in rows) {
      final schedule = JsonCodec.mapAt(row, 'schedule') ?? const {};
      final times = schedule['times'];
      if (times is List && times.isNotEmpty) {
        for (var i = 0; i < times.length; i++) {
          final time = times[i]?.toString() ?? '';
          expanded.add({
            ...row,
            'timeLabel': time,
            'id': JsonCodec.stringOr(
              row['id'] ?? row['occurrenceId'],
              '${JsonCodec.stringOr(row['medicationId'], 'med')}-$i',
            ),
          });
        }
      } else {
        expanded.add(row);
      }
    }
    return expanded;
  }

  /// Overlay /mar/round occurrence state/time onto /mar/due rows when IDs match.
  static List<Map<String, dynamic>> _mergeRoundOntoDue({
    required List<Map<String, dynamic>> dueRows,
    required List<Map<String, dynamic>> roundRows,
  }) {
    if (roundRows.isEmpty) return dueRows;
    if (dueRows.isEmpty) return roundRows;

    final byKey = <String, Map<String, dynamic>>{};
    for (final row in roundRows) {
      final key = _doseMatchKey(row);
      if (key != null) byKey[key] = row;
    }
    if (byKey.isEmpty) return dueRows;

    return dueRows.map((row) {
      final key = _doseMatchKey(row);
      final round = key == null ? null : byKey[key];
      if (round == null) return row;
      return {
        ...row,
        if (round['state'] != null || round['status'] != null)
          'state': round['state'] ?? round['status'],
        if (round['scheduledAt'] != null) 'scheduledAt': round['scheduledAt'],
        if (round['dueAt'] != null) 'dueAt': round['dueAt'],
        if (round['timeLabel'] != null) 'timeLabel': round['timeLabel'],
        if (round['assignee'] != null) 'assignee': round['assignee'],
        if (round['administeredBy'] != null)
          'administeredBy': round['administeredBy'],
      };
    }).toList();
  }

  static String? _doseMatchKey(Map<String, dynamic> row) {
    final medId = JsonCodec.string(row['medicationId'] ?? row['id']);
    final clientId = JsonCodec.string(row['clientId']);
    final time = JsonCodec.string(row['timeLabel']) ??
        JsonCodec.string(row['scheduledAt']) ??
        JsonCodec.string(row['dueAt']);
    if (medId == null || medId.isEmpty) return null;
    return '$medId|${clientId ?? ''}|${time ?? ''}';
  }

  /// Parse GET /reports/series?metric=mar into a “92%” style label.
  static String _complianceLabel(dynamic seriesBody) {
    if (seriesBody == null) return '—';
    final map = JsonCodec.unwrapMap(seriesBody);
    final direct = map['compliance'] ??
        map['rate'] ??
        map['percentage'] ??
        map['value'] ??
        map['summary'] ??
        JsonCodec.mapAt(map, 'summary')?['compliance'] ??
        JsonCodec.mapAt(map, 'totals')?['compliance'];
    final fromDirect = _asPercentLabel(direct);
    if (fromDirect != null) return fromDirect;

    final points = JsonCodec.listAt(map, 'points');
    if (points.isEmpty) return '—';

    var sum = 0.0;
    var count = 0;
    for (final point in points) {
      if (point is! Map) continue;
      final row = JsonCodec.asMap(point);
      final value = row['value'] ?? row['compliance'] ?? row['rate'];
      if (value is num) {
        sum += value.toDouble();
        count++;
      } else if (value is String) {
        final parsed = double.tryParse(value.replaceAll('%', '').trim());
        if (parsed != null) {
          sum += parsed;
          count++;
        }
      }
    }
    if (count == 0) return '—';
    return _asPercentLabel(sum / count) ?? '—';
  }

  static String? _asPercentLabel(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty) return null;
      if (text.contains('%')) return text;
      final parsed = double.tryParse(text);
      if (parsed == null) return text;
      return _asPercentLabel(parsed);
    }
    if (raw is num) {
      final value = raw.toDouble();
      final pct = value >= 0 && value <= 1 ? value * 100 : value;
      return '${pct.round()}%';
    }
    return null;
  }

  static List<Map<String, dynamic>> _rows(dynamic body, {String? extraKey}) {
    if (body == null) return const [];
    final json = JsonCodec.unwrapMap(body);
    if (extraKey != null) {
      final nested = JsonCodec.listAt(json, extraKey);
      if (nested.isNotEmpty) {
        return nested.whereType<Map>().map(JsonCodec.asMap).toList();
      }
    }
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();
  }

  static MedicationDose _overviewDose(Map<String, dynamic> json) {
    final name = _resident(json);
    final scheduled = JsonCodec.dateTime(
      json['scheduledAt'] ?? json['dueAt'] ?? json['time'],
    );
    final timeFromSchedule = JsonCodec.string(json['timeLabel']);
    return MedicationDose(
      id: JsonCodec.stringOr(json['id'] ?? json['occurrenceId'], name),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.blue,
      medicationName: _medName(json),
      dose: _dose(json),
      timeLabel: scheduled != null
          ? IsoDateRange.timeLabel(scheduled.toLocal())
          : (timeFromSchedule ?? ''),
    );
  }

  static ScheduleDose _schedule(Map<String, dynamic> json, DoseStatus status) {
    final name = _resident(json);
    final assignee = json['assignee'] ?? json['staff'] ?? json['administeredBy'];
    final assigneeName = assignee == null
        ? JsonCodec.stringOr(json['assigneeName'], '')
        : IsoDateRange.personName(assignee);
    final scheduled = JsonCodec.dateTime(
      json['scheduledAt'] ?? json['dueAt'] ?? json['time'],
    );
    final timeFromSchedule = JsonCodec.string(json['timeLabel']);
    final hourFromLabel = _hourFromTimeLabel(timeFromSchedule);
    return ScheduleDose(
      id: JsonCodec.stringOr(json['id'] ?? json['occurrenceId'], name),
      clientId: JsonCodec.string(
        json['clientId'] ?? JsonCodec.mapAt(json, 'client')?['id'],
      ),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.blue,
      medicationName: _medName(json),
      dose: _dose(json),
      scheduledTime: scheduled != null
          ? IsoDateRange.timeLabel(scheduled.toLocal())
          : (timeFromSchedule ?? ''),
      scheduledHour: scheduled?.toLocal().hour ?? hourFromLabel,
      assigneeName: assigneeName,
      assigneeInitials: IsoDateRange.initials(assigneeName, fallback: '--'),
      assigneeAvatarColor: AvatarPalette.green,
      status: status,
    );
  }

  static int? _hourFromTimeLabel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.trim().split(':');
    if (parts.isEmpty) return null;
    return int.tryParse(parts.first);
  }

  static MissedMedication _missed(Map<String, dynamic> json) {
    final name = _resident(json);
    final assignee = json['assignee'] ?? json['staff'] ?? json['scheduledStaff'];
    final assigneeName = assignee == null
        ? JsonCodec.stringOr(json['assigneeName'], 'Unassigned')
        : IsoDateRange.personName(assignee);
    final scheduled = JsonCodec.dateTime(
      json['scheduledAt'] ?? json['dueAt'] ?? json['missedAt'],
    );
    return MissedMedication(
      id: JsonCodec.stringOr(json['id'] ?? json['occurrenceId'], name),
      clientId: _clientId(json),
      residenceId: JsonCodec.string(json['residenceId']),
      assigneeUserId: _personUserId(assignee) ??
          JsonCodec.string(json['assigneeUserId'] ?? json['staffUserId']),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.purple,
      medicationName: _medName(json),
      dose: _dose(json),
      scheduledTime: scheduled == null
          ? ''
          : IsoDateRange.timeLabel(scheduled.toLocal()),
      missedTimeAgo: scheduled == null
          ? JsonCodec.stringOr(json['status'], 'Missed')
          : IsoDateRange.timeAgo(scheduled),
      assigneeName: assigneeName,
      assigneeInitials: IsoDateRange.initials(assigneeName),
      assigneeAvatarColor: AvatarPalette.green,
      isCritical: JsonCodec.boolean(json['isCritical'] ?? json['critical']) ?? false,
    );
  }

  static RefusedMedication _refused(Map<String, dynamic> json) {
    final name = _resident(json);
    final reporter = json['reportedBy'] ?? json['staff'] ?? json['administeredBy'];
    final reporterName = reporter == null
        ? JsonCodec.stringOr(json['reportedByName'], 'Staff')
        : IsoDateRange.personName(reporter);
    final at = JsonCodec.dateTime(
      json['refusedAt'] ?? json['administeredAt'] ?? json['updatedAt'],
    );
    return RefusedMedication(
      id: JsonCodec.stringOr(json['id'] ?? json['occurrenceId'], name),
      clientId: _clientId(json),
      residenceId: JsonCodec.string(json['residenceId']),
      reportedByUserId: _personUserId(reporter) ??
          JsonCodec.string(json['reportedByUserId'] ?? json['staffUserId']),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.green,
      medicationName: _medName(json),
      dose: _dose(json),
      refusedTime: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      reason: JsonCodec.stringOr(json['reason'] ?? json['note'] ?? json['comment'], ''),
      reportedByName: reporterName,
      reportedByInitials: IsoDateRange.initials(reporterName),
      reportedByAvatarColor: AvatarPalette.blue,
      needsFollowUp: JsonCodec.boolean(json['needsFollowUp'] ?? json['followUp']) ?? true,
    );
  }

  static String? _clientId(Map<String, dynamic> json) {
    return JsonCodec.string(
      json['clientId'] ?? JsonCodec.mapAt(json, 'client')?['id'],
    );
  }

  static String? _personUserId(dynamic value) {
    if (value is! Map) return null;
    final map = JsonCodec.asMap(value);
    return JsonCodec.string(map['userId'] ?? map['id'] ?? map['staffId']);
  }

  static MedicationAlert _alert(Map<String, dynamic> json, AlertKind kind) {
    final name = _resident(json);
    final at = JsonCodec.dateTime(
      json['scheduledAt'] ?? json['missedAt'] ?? json['refusedAt'],
    );
    return MedicationAlert(
      id: JsonCodec.stringOr(json['id'] ?? json['occurrenceId'], name),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.blue,
      medicationName: '${_medName(json)} ${_dose(json)}'.trim(),
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      kind: kind,
      note: JsonCodec.stringOr(json['reason'] ?? json['note'] ?? json['comment'], ''),
    );
  }

  static String _resident(Map<String, dynamic> json) {
    final client = JsonCodec.mapAt(json, 'client') ??
        JsonCodec.mapAt(json, 'resident') ??
        {};
    return IsoDateRange.personName(
      client.isEmpty ? json['clientName'] ?? json['residentName'] : client,
    );
  }

  static String _medName(Map<String, dynamic> json) {
    return JsonCodec.stringOr(
      json['medicationName'] ??
          JsonCodec.mapAt(json, 'medication')?['name'] ??
          json['name'],
      'Medication',
    );
  }

  static String _dose(Map<String, dynamic> json) {
    return JsonCodec.stringOr(
      json['dose'] ??
          json['strength'] ??
          JsonCodec.mapAt(json, 'medication')?['dose'],
      '',
    );
  }

  static List<ClientMedicationItem> clientMedicationsFrom(
    dynamic body, {
    required bool isPrn,
  }) {
    return _rows(body).map((json) {
      final schedule = JsonCodec.mapAt(json, 'schedule') ?? const {};
      final times = schedule['times'] ?? json['scheduleTimes'];
      String? scheduleLabel;
      if (times is List && times.isNotEmpty) {
        scheduleLabel = times.map((t) => t.toString()).join(', ');
      } else {
        scheduleLabel = JsonCodec.string(
          json['scheduleFrequency'] ?? schedule['frequency'],
        );
      }
      return ClientMedicationItem(
        id: JsonCodec.stringOr(json['id'], 'med'),
        name: JsonCodec.stringOr(json['name'] ?? json['medicationName'], 'Medication'),
        dose: JsonCodec.stringOr(json['dose'], ''),
        scheduleLabel: scheduleLabel,
        instructions: JsonCodec.string(json['instructions'] ?? json['notes']),
        isPrn: isPrn,
      );
    }).toList();
  }

  const MedicationMapper._();
}
