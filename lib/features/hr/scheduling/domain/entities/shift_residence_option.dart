import 'package:flutter/foundation.dart';

/// A selectable residence from `GET /residences` for Create Shift.
@immutable
class ShiftResidenceOption {
  final String id;
  final String name;

  /// `stateProvince` — drives provincial holidays on the calendars.
  final String? province;

  const ShiftResidenceOption({
    required this.id,
    required this.name,
    this.province,
  });
}

/// A resident from `GET /clients?residenceId=` for the one-to-one field.
@immutable
class ShiftClientOption {
  final String id;
  final String name;

  const ShiftClientOption({
    required this.id,
    required this.name,
  });
}
