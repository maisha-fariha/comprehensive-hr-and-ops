import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/administered_dose.dart';
import '../../domain/entities/due_dose.dart';
import '../../domain/entities/missed_dose.dart';
import '../../domain/entities/refused_dose.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../domain/entities/staff_medication_overview.dart';

abstract final class StaffMedicationMapper {
  static StaffMedicationOverview fromRound(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final occurrences = JsonCodec.listAt(json, 'occurrences').isEmpty
        ? JsonCodec.unwrapList(body)
        : JsonCodec.listAt(json, 'occurrences');

    final dueNow = <DueDose>[];
    final later = <DueDose>[];
    final administered = <AdministeredDose>[];
    final missed = <MissedDose>[];
    final refused = <RefusedDose>[];

    for (final item in occurrences) {
      if (item is! Map) continue;
      final row = JsonCodec.asMap(item);
      final state = (JsonCodec.string(row['state'] ?? row['status']) ?? '')
          .toLowerCase();
      if (state == 'given' || state == 'late' || state == 'administered') {
        administered.add(_administered(row));
      } else if (state == 'refused') {
        refused.add(_refused(row));
      } else if (state == 'missed') {
        missed.add(_missed(row));
      } else if (state == 'upcoming') {
        later.add(
          _due(row, DueDoseSection.laterToday, DueDoseStatus.upcoming),
        );
      } else {
        dueNow.add(_due(row, DueDoseSection.dueNow, DueDoseStatus.pending));
      }
    }

    return StaffMedicationOverview(
      screenTitle: 'Medication MAR',
      dueNowDoses: dueNow,
      laterTodayDoses: later,
      administeredDoses: administered,
      missedDoses: missed,
      refusedDoses: refused,
    );
  }

  static DueDose _due(
    Map<String, dynamic> json,
    DueDoseSection section,
    DueDoseStatus status,
  ) {
    final name = _residentName(json);
    final scheduled = JsonCodec.dateTime(
      json['scheduledAt'] ?? json['dueAt'] ?? json['time'],
    );
    return DueDose(
      id: JsonCodec.stringOr(json['id'] ?? json['occurrenceId'], name),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.blue,
      medicationName: _medName(json),
      dose: _dose(json),
      route: _route(json),
      timeLabel: scheduled == null
          ? JsonCodec.stringOr(json['timeLabel'], '')
          : IsoDateRange.timeLabel(scheduled.toLocal()),
      section: section,
      status: status,
      clientId: JsonCodec.stringOr(
        json['clientId'] ?? JsonCodec.mapAt(json, 'client')?['id'],
        '',
      ),
      residenceId: JsonCodec.stringOr(
        json['residenceId'] ?? JsonCodec.mapAt(json, 'residence')?['id'],
        '',
      ),
      medicationId: JsonCodec.stringOr(
        json['medicationId'] ?? JsonCodec.mapAt(json, 'medication')?['id'],
        '',
      ),
    );
  }

  static AdministeredDose _administered(Map<String, dynamic> json) {
    final name = _residentName(json);
    final given = JsonCodec.dateTime(
      json['administeredAt'] ?? json['givenAt'] ?? json['updatedAt'],
    );
    return AdministeredDose(
      id: JsonCodec.stringOr(json['id'], name),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.green,
      medicationName: _medName(json),
      dose: _dose(json),
      route: _route(json),
      givenTimeLabel: given == null
          ? ''
          : IsoDateRange.timeLabel(given.toLocal()),
      administeredByName: IsoDateRange.personName(
        json['administeredBy'] ?? json['givenBy'] ?? json['staff'],
      ),
    );
  }

  static MissedDose _missed(Map<String, dynamic> json) {
    final name = _residentName(json);
    final scheduled = JsonCodec.dateTime(json['scheduledAt'] ?? json['dueAt']);
    return MissedDose(
      id: JsonCodec.stringOr(json['id'], name),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.red,
      medicationName: _medName(json),
      dose: _dose(json),
      route: _route(json),
      scheduledTimeLabel: scheduled == null
          ? ''
          : IsoDateRange.timeLabel(scheduled.toLocal()),
      missedByName: IsoDateRange.personName(json['recordedBy'] ?? json['staff']),
      reason: JsonCodec.stringOr(json['notes'] ?? json['reason'], ''),
    );
  }

  static RefusedDose _refused(Map<String, dynamic> json) {
    final name = _residentName(json);
    final when = JsonCodec.dateTime(
      json['administeredAt'] ?? json['refusedAt'] ?? json['updatedAt'],
    );
    return RefusedDose(
      id: JsonCodec.stringOr(json['id'], name),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.amber,
      medicationName: _medName(json),
      dose: _dose(json),
      route: _route(json),
      timeLabel: when == null ? '' : IsoDateRange.timeLabel(when.toLocal()),
      refusedByName: IsoDateRange.personName(json['recordedBy'] ?? json['staff']),
      notes: JsonCodec.stringOr(json['notes'] ?? json['reason'], ''),
    );
  }

  static String _residentName(Map<String, dynamic> json) {
    final client = JsonCodec.mapAt(json, 'client') ?? {};
    return JsonCodec.stringOr(
      client['preferredName'] ??
          client['name'] ??
          json['clientName'] ??
          json['residentName'],
      'Client',
    );
  }

  static String _medName(Map<String, dynamic> json) {
    final med = JsonCodec.mapAt(json, 'medication') ?? {};
    return JsonCodec.stringOr(
      med['name'] ?? json['medicationName'] ?? json['name'],
      'Medication',
    );
  }

  static String _dose(Map<String, dynamic> json) {
    final med = JsonCodec.mapAt(json, 'medication') ?? {};
    return JsonCodec.stringOr(
      json['dose'] ?? json['strength'] ?? med['strength'] ?? med['dose'],
      '',
    );
  }

  static MedicationRoute _route(Map<String, dynamic> json) {
    final raw = (JsonCodec.string(json['route']) ??
            JsonCodec.string(JsonCodec.mapAt(json, 'medication')?['route']) ??
            '')
        .toLowerCase();
    if (raw.contains('inject') || raw.contains('subcut')) {
      return MedicationRoute.injectionSubcut;
    }
    if (raw.contains('capsule')) return MedicationRoute.capsuleOral;
    return MedicationRoute.tabletOral;
  }

  const StaffMedicationMapper._();
}
