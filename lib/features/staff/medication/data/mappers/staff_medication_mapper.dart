import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/administered_dose.dart';
import '../../domain/entities/due_dose.dart';
import '../../domain/entities/missed_dose.dart';
import '../../domain/entities/refused_dose.dart';
import '../../domain/entities/staff_client_medication_item.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../domain/entities/staff_medication_overview.dart';

abstract final class StaffMedicationMapper {
  /// Maps `GET /mar/round` into all four tab lists + summary counters.
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
    var overdueFromOcc = 0;

    for (final item in occurrences) {
      if (item is! Map) continue;
      final row = JsonCodec.asMap(item);
      final state = (JsonCodec.string(row['state'] ?? row['status']) ?? '')
          .toLowerCase()
          .trim();

      // Administered: given | late (| administered alias)
      if (state == 'given' || state == 'late' || state == 'administered') {
        administered.add(_administered(row));
        continue;
      }

      // Refused
      if (state == 'refused') {
        refused.add(_refused(row));
        continue;
      }

      // Missed (+ overdue also appears under Missed per B6 map)
      if (state == 'missed' || state == 'overdue') {
        missed.add(_missed(row));
        if (state == 'overdue') overdueFromOcc += 1;
        if (state == 'missed') continue;
        // overdue also stays in Due Now below
      }

      // Due Now / Later Today: due | upcoming | overdue
      if (state == 'upcoming') {
        later.add(
          _due(
            row,
            DueDoseSection.laterToday,
            DueDoseStatus.upcoming,
            webState: 'upcoming',
          ),
        );
      } else if (state == 'due' ||
          state == 'overdue' ||
          state.isEmpty ||
          state == 'pending') {
        final webState = state == 'overdue'
            ? 'overdue'
            : (state.isEmpty || state == 'pending' ? 'due' : state);
        dueNow.add(
          _due(
            row,
            DueDoseSection.dueNow,
            DueDoseStatus.pending,
            webState: webState,
          ),
        );
      }
    }

    final summary = JsonCodec.mapAt(json, 'summary') ?? const {};
    final dueSummary = JsonCodec.integer(summary['due']);
    final administeredSummary = JsonCodec.integer(
      summary['administered'] ?? summary['given'],
    );
    final missedSummary = JsonCodec.integer(summary['missed']);
    final refusedSummary = JsonCodec.integer(summary['refused']);
    final scheduledSummary = JsonCodec.integer(
      summary['scheduled'] ?? summary['scheduledToday'],
    );
    final overdueSummary = JsonCodec.integer(summary['overdue']);
    final unscheduledSummary = JsonCodec.integer(summary['unscheduled']);
    final complianceRaw = summary['complianceRate'];
    double? complianceRate;
    if (complianceRaw is num) {
      complianceRate = complianceRaw.toDouble();
    } else if (complianceRaw is String) {
      complianceRate = double.tryParse(complianceRaw);
    }

    return StaffMedicationOverview(
      screenTitle: 'Medication Administration Record (MAR)',
      dueNowDoses: dueNow,
      laterTodayDoses: later,
      administeredDoses: administered,
      missedDoses: missed,
      refusedDoses: refused,
      dueCount: dueSummary,
      administeredCount: administeredSummary,
      missedCount: missedSummary,
      refusedCount: refusedSummary,
      scheduledCount: scheduledSummary,
      overdueCount: overdueSummary ?? (overdueFromOcc > 0 ? overdueFromOcc : null),
      unscheduledCount: unscheduledSummary,
      complianceRate: complianceRate,
    );
  }

  static List<StaffClientMedicationItem> clientMedicationsFrom(
    dynamic body, {
    required bool isPrn,
  }) {
    return JsonCodec.unwrapList(body).whereType<Map>().map((item) {
      final json = JsonCodec.asMap(item);
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
      final client = JsonCodec.mapAt(json, 'client');
      final residence = JsonCodec.mapAt(json, 'residence');
      final first = JsonCodec.stringOr(client?['firstName'], '');
      final last = JsonCodec.stringOr(client?['lastName'], '');
      final composed = '$first $last'.trim();
      return StaffClientMedicationItem(
        id: JsonCodec.stringOr(json['id'], 'med'),
        name: JsonCodec.stringOr(
          json['name'] ?? json['medicationName'],
          'Medication',
        ),
        dose: JsonCodec.stringOr(json['dose'] ?? json['strength'], ''),
        scheduleLabel: scheduleLabel,
        instructions: JsonCodec.string(json['instructions'] ?? json['notes']),
        isPrn: isPrn,
        clientId: JsonCodec.stringOr(
          json['clientId'] ?? client?['id'],
          '',
        ),
        clientName: JsonCodec.stringOr(
          client?['preferredName'] ??
              client?['name'] ??
              client?['fullName'] ??
              (composed.isEmpty ? null : composed),
          '',
        ),
        residenceId: JsonCodec.stringOr(
          json['residenceId'] ?? residence?['id'],
          '',
        ),
        residenceName: JsonCodec.stringOr(
          json['residenceName'] ?? residence?['name'],
          '',
        ),
      );
    }).toList();
  }

  static DueDose _due(
    Map<String, dynamic> json,
    DueDoseSection section,
    DueDoseStatus status, {
    String webState = 'due',
  }) {
    final name = _residentName(json);
    final scheduled = JsonCodec.dateTime(
      json['scheduledAt'] ?? json['dueAt'] ?? json['time'],
    );
    return DueDose(
      id: JsonCodec.stringOr(
        json['id'] ?? json['occurrenceId'],
        name,
      ),
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
      state: webState,
      clientId: JsonCodec.stringOr(
        json['clientId'] ?? JsonCodec.mapAt(json, 'client')?['id'],
        '',
      ),
      residenceId: JsonCodec.stringOr(
        json['residenceId'] ?? JsonCodec.mapAt(json, 'residence')?['id'],
        '',
      ),
      residenceName: JsonCodec.stringOr(
        JsonCodec.mapAt(json, 'residence')?['name'] ??
            json['residenceName'] ??
            json['houseName'],
        '',
      ),
      medicationId: JsonCodec.stringOr(
        json['medicationId'] ??
            json['prnMedicationId'] ??
            JsonCodec.mapAt(json, 'medication')?['id'] ??
            JsonCodec.mapAt(json, 'prnMedication')?['id'],
        '',
      ),
      isPrn: _isPrn(json),
    );
  }

  static AdministeredDose _administered(Map<String, dynamic> json) {
    final name = _residentName(json);
    final given = JsonCodec.dateTime(
      json['administeredAt'] ?? json['givenAt'] ?? json['updatedAt'],
    );
    final staff = JsonCodec.mapAt(json, 'administeredByStaff') ??
        JsonCodec.mapAt(json, 'staff');
    final status = (JsonCodec.string(json['status']) ?? 'administered')
        .toLowerCase();
    final outcome = switch (status) {
      'administered' || 'given' || 'late' => 'Given',
      'refused' => 'Refused',
      'withheld' => 'Withheld',
      'not_available' => 'Not available',
      'missed' => 'Missed',
      _ => status.isEmpty ? 'Given' : status,
    };
    return AdministeredDose(
      id: JsonCodec.stringOr(json['id'], name),
      residentName: name,
      residentInitials: IsoDateRange.initials(name),
      avatarColor: AvatarPalette.green,
      medicationName: _medName(json),
      dose: _dose(json),
      route: _route(json),
      givenTimeLabel: given == null ? '' : _givenStamp(given.toLocal()),
      administeredByName: JsonCodec.stringOr(
        staff?['name'] ??
            IsoDateRange.personName(
              json['administeredBy'] ?? json['givenBy'] ?? json['staff'],
            ),
        '—',
      ),
      outcomeLabel: outcome,
      residenceName: JsonCodec.stringOr(
        JsonCodec.mapAt(json, 'residence')?['name'] ??
            json['residenceName'] ??
            json['houseName'],
        '',
      ),
    );
  }

  /// Web Given column style: `Aug 27, 09:33 AM`.
  static String _givenStamp(DateTime local) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h24 = local.hour;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final ampm = h24 >= 12 ? 'PM' : 'AM';
    final mm = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, '
        '${h12.toString().padLeft(2, '0')}:$mm $ampm';
  }

  /// Maps `GET /mar/administrations` list payload.
  static List<AdministeredDose> administrationsFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => _administered(JsonCodec.asMap(item)))
        .toList();
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
      refusedByName:
          IsoDateRange.personName(json['recordedBy'] ?? json['staff']),
      notes: JsonCodec.stringOr(json['notes'] ?? json['reason'], ''),
    );
  }

  static bool _isPrn(Map<String, dynamic> json) {
    if (json['prnMedicationId'] != null ||
        JsonCodec.mapAt(json, 'prnMedication') != null) {
      return true;
    }
    final source = (JsonCodec.string(json['source']) ?? '').toLowerCase();
    if (source == 'prn') return true;
    final med = JsonCodec.mapAt(json, 'medication') ?? {};
    return JsonCodec.boolean(json['isPrn'] ?? med['isPrn'] ?? med['prn']) ==
        true;
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
    final med = JsonCodec.mapAt(json, 'medication') ??
        JsonCodec.mapAt(json, 'prnMedication') ??
        {};
    return JsonCodec.stringOr(
      med['name'] ?? json['medicationName'] ?? json['name'],
      'Medication',
    );
  }

  static String _dose(Map<String, dynamic> json) {
    final med = JsonCodec.mapAt(json, 'medication') ??
        JsonCodec.mapAt(json, 'prnMedication') ??
        {};
    return JsonCodec.stringOr(
      json['dose'] ?? json['strength'] ?? med['strength'] ?? med['dose'],
      '',
    );
  }

  static MedicationRoute _route(Map<String, dynamic> json) {
    final raw = (JsonCodec.string(json['route']) ??
            JsonCodec.string(
              JsonCodec.mapAt(json, 'medication')?['route'] ??
                  JsonCodec.mapAt(json, 'prnMedication')?['route'],
            ) ??
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
