import 'package:flutter/foundation.dart';

/// A selectable residence from `GET /residences` for Create Shift.
@immutable
class ShiftResidenceOption {
  final String id;
  final String name;

  const ShiftResidenceOption({
    required this.id,
    required this.name,
  });
}
