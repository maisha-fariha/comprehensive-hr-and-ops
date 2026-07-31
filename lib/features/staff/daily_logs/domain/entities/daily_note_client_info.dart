import 'package:flutter/foundation.dart';

/// The client identity shown in the info card at the top of the "Daily
/// Note" screen. Passed in directly via navigation from whichever Daily
/// Logs client row/card was tapped, rather than fetched from the
/// repository - the note-taking form itself is what's fetched.
@immutable
class DailyNoteClientInfo {
  final String initials;
  final String name;
  final String dobLabel;
  final String roomLabel;

  const DailyNoteClientInfo({
    required this.initials,
    required this.name,
    required this.dobLabel,
    required this.roomLabel,
  });

  /// First name only, used to fill in the "How is {firstName} today?"
  /// section header.
  String get firstName => name.split(' ').first;

  /// Default placeholder used if the "Daily Note" screen is opened without
  /// a specific client context (e.g. deep link), matching the reference
  /// screenshot's James D. example.
  static const DailyNoteClientInfo fallback = DailyNoteClientInfo(
    initials: 'JD',
    name: 'James D.',
    dobLabel: 'DOB 05/12/1965',
    roomLabel: 'Room 101',
  );
}
