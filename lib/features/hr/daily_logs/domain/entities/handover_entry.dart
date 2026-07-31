import 'package:flutter/foundation.dart';

import 'handover_note.dart';

/// A single card in the Handover tab's "Handover Timeline" list.
///
/// A "full" entry (e.g. the urgent Morning → Evening handover) carries staff
/// avatars, important notes and an acknowledgement caption/button. A
/// "compact" entry (e.g. the routine Night → Morning handover) only shows
/// the shift-transition header and a small tag, matching the cut-off second
/// entry visible at the bottom of the reference screenshot.
@immutable
class HandoverEntry {
  final String id;
  final String fromShiftLabel;
  final String toShiftLabel;
  final bool isUrgent;

  /// Small trailing tag shown on compact entries instead of the "Urgent"
  /// pill, e.g. "\$ Routine".
  final String? tagLabel;

  final String? fromStaffName;
  final String? fromStaffInitials;
  final String? toStaffName;
  final String? toStaffInitials;

  final List<HandoverNote> notes;
  final String? acknowledgementCaption;

  const HandoverEntry({
    required this.id,
    required this.fromShiftLabel,
    required this.toShiftLabel,
    this.isUrgent = false,
    this.tagLabel,
    this.fromStaffName,
    this.fromStaffInitials,
    this.toStaffName,
    this.toStaffInitials,
    this.notes = const [],
    this.acknowledgementCaption,
  });

  /// A compact entry has no staff avatars/notes to render - just the header.
  bool get isCompact => fromStaffName == null && notes.isEmpty;
}
