import 'package:flutter/foundation.dart';

/// An id / label pair for the MAR pickers (houses, staff, checks).
@immutable
class MarOption {
  final String id;
  final String label;

  const MarOption({required this.id, required this.label});
}

/// A resident for the MAR pickers, with the house they live in.
@immutable
class MarClientOption {
  final String id;
  final String name;
  final String residenceId;

  const MarClientOption({required this.id, required this.name, this.residenceId = ''});
}
