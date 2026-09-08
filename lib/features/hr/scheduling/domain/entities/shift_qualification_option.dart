import 'package:flutter/foundation.dart';

/// A selectable required qualification for Create Shift.
///
/// Built from unique `categoryId` + category name values on `GET /staff`.
@immutable
class ShiftQualificationOption {
  final String id;
  final String label;

  const ShiftQualificationOption({
    required this.id,
    required this.label,
  });
}
