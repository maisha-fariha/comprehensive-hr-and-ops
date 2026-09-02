import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
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
    required String? residenceName,
  }) {
    final dueRows = _rows(dueBody, extraKey: 'occurrences');
    final roundRows = _rows(roundBody, extraKey: 'occurrences');
    final missedRows = _rows(missedBody);
    final refusedRows = _rows(refusedBody);
    final dueNow = <ScheduleDose>[];
    final later = <ScheduleDose>[];
    for (final row in roundRows.isEmpty ? dueRows : roundRows) {
      final state = (JsonCodec.string(row['state'] ?? row['status']) ?? '')
          .toLowerCase();
      if (state == 'upcoming' || state == 'scheduled') {
        later.add(_schedule(row, DoseStatus.upcoming));
      } else if (state == 'given' || state == 'administered' || state == 'late') {
        later.add(_schedule(row, DoseStatus.completed));
      } else {
        dueNow.add(_schedule(row, DoseStatus.due));
      }
    }
    final uniqueDue = dueNow.isNotEmpty ? dueNow.length : dueRows.length;

    return MedicationOverview(
      screenTitle: 'Medication MAR',
      screenSubtitle: residenceName == null ? 'Oversight' : 'Oversight · $residenceName',
      dueCount: uniqueDue,
      missedCount: missedRows.length,
      refusedCount: refusedRows.length,
      overviewStats: [
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
      dueTodayDoses: (roundRows.isNotEmpty ? roundRows : dueRows)
          .map(_overviewDose)
          .take(5)
          .toList(),
      moreDueTodayCount: (uniqueDue - 5).clamp(0, uniqueDue),
      missedRefusedAlerts: [
        ...missedRows.map((row) => _alert(row, AlertKind.missed)),
        ...refusedRows.map((row) => _alert(row, AlertKind.refused)),
      ],
      scheduleTitle: "Today's Medication Schedule",
      scheduleSubtitle: '${dueNow.length} due now · ${later.length} later',
      priorityDoses: dueNow,
      laterTodayDoses: later,
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

  static List<Map<String, dynamic>> _rows(dynamic body, {String? extraKey}) {
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
    return MedicationDose(
      id: JsonCodec.stringOr(json['id'] ?? json['occurrenceId'], name),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.blue,
      medicationName: _medName(json),
      dose: _dose(json),
      timeLabel: scheduled == null
          ? JsonCodec.stringOr(json['timeLabel'], '')
          : IsoDateRange.timeLabel(scheduled.toLocal()),
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
    return ScheduleDose(
      id: JsonCodec.stringOr(json['id'] ?? json['occurrenceId'], name),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.blue,
      medicationName: _medName(json),
      dose: _dose(json),
      scheduledTime: scheduled == null
          ? JsonCodec.stringOr(json['timeLabel'], '')
          : IsoDateRange.timeLabel(scheduled.toLocal()),
      assigneeName: assigneeName,
      assigneeInitials: IsoDateRange.initials(assigneeName, fallback: '--'),
      assigneeAvatarColor: AvatarPalette.green,
      status: status,
    );
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

  const MedicationMapper._();
}
