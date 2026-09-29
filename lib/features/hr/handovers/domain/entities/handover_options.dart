/// A plain select option (residence, staff member or resident).
class HandoverOption {
  final String id;
  final String label;

  const HandoverOption({required this.id, required this.label});
}

/// A person on a shift, as `/shifts` lists them.
class HandoverShiftStaff {
  final String id;
  final String? name;
  final String? status;

  const HandoverShiftStaff({required this.id, this.name, this.status});

  bool get rostered => status != 'declined' && status != 'bid_pending';
}

/// A `/shifts` row used by the Record handover form.
class HandoverShift {
  final String id;
  final String? residenceId;
  final String? residenceName;
  final String? title;
  final String? shiftType;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<HandoverShiftStaff> staff;

  const HandoverShift({
    required this.id,
    this.residenceId,
    this.residenceName,
    this.title,
    this.shiftType,
    this.startsAt,
    this.endsAt,
    this.staff = const [],
  });

  List<String> get rosteredNames => [
        for (final person in staff)
          if (person.rostered && (person.name ?? '').isNotEmpty) person.name!,
      ];
}

/// One resident's section of a new handover.
class HandoverClientDraft {
  final String clientId;
  final String clientName;
  String status = 'stable';
  final Map<String, String> health = {};
  final Map<String, String> medication = {};
  final List<String> careCompleted = [];
  final Map<String, String> care = {};

  HandoverClientDraft({required this.clientId, required this.clientName});

  static bool _hasText(Map<String, String> values) =>
      values.values.any((v) => v.trim().isNotEmpty);

  /// The web sends only the sections that have something written in them.
  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'status': status,
        if (_hasText(health)) 'health': Map.of(health),
        if (_hasText(medication)) 'medication': Map.of(medication),
        if (careCompleted.isNotEmpty || _hasText(care))
          'care': {...care, 'completed': List.of(careCompleted)},
      };
}

/// An outstanding job typed on the Record handover form.
class HandoverJobDraft {
  final String title;

  /// `normal`, `important` or `urgent`.
  final String priority;

  const HandoverJobDraft({required this.title, required this.priority});

  Map<String, dynamic> toJson() => {'title': title, 'priority': priority};
}
