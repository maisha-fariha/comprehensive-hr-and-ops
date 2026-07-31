import 'package:flutter/foundation.dart';

import 'daily_logs_enums.dart';

/// A single bullet inside a handover entry's "Important Notes" list.
@immutable
class HandoverNote {
  final HandoverNoteType type;
  final String title;
  final String description;

  const HandoverNote({
    required this.type,
    required this.title,
    required this.description,
  });
}
