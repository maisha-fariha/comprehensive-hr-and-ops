import 'package:flutter/foundation.dart';

import 'family_daily_update_entry.dart';

/// Linked resident option for the Care Journal client picker.
@immutable
class FamilyCareJournalClient {
  final String id;
  final String name;
  final bool activities;
  final bool incidents;
  final bool medications;
  final bool medicalConditions;
  final bool documents;
  final bool appointments;
  final bool messages;

  const FamilyCareJournalClient({
    required this.id,
    required this.name,
    this.activities = true,
    this.incidents = false,
    this.medications = false,
    this.medicalConditions = false,
    this.documents = false,
    this.appointments = true,
    this.messages = true,
  });
}

@immutable
class FamilyCareJournalDay {
  final String id;
  final DateTime? logDate;
  final String dateLabel;
  final List<FamilyDailyUpdateEntry> notes;
  /// Care-note count only (web "recorded updates" / "entries").
  final int careNoteCount;
  final int activityCount;
  final List<String> mediaUrls;

  const FamilyCareJournalDay({
    required this.id,
    required this.logDate,
    required this.dateLabel,
    required this.notes,
    this.careNoteCount = 0,
    this.activityCount = 0,
    this.mediaUrls = const [],
  });
}

@immutable
class FamilyMedicationItem {
  final String id;
  final String name;
  final String dose;
  final String route;
  final String frequency;
  final List<String> times;

  const FamilyMedicationItem({
    required this.id,
    required this.name,
    required this.dose,
    required this.route,
    required this.frequency,
    this.times = const [],
  });
}

@immutable
class FamilyMedicalConditions {
  final List<String> diagnoses;
  final List<String> allergies;
  final String? dietaryRequirements;

  const FamilyMedicalConditions({
    this.diagnoses = const [],
    this.allergies = const [],
    this.dietaryRequirements,
  });

  bool get isEmpty =>
      diagnoses.isEmpty &&
      allergies.isEmpty &&
      (dietaryRequirements == null || dietaryRequirements!.trim().isEmpty);
}

@immutable
class FamilyCareMoment {
  final String url;
  final String? activityId;
  final String activityType;
  final String description;
  final DateTime? takenOn;

  const FamilyCareMoment({
    required this.url,
    required this.description,
    this.activityId,
    this.activityType = '',
    this.takenOn,
  });
}

@immutable
class FamilyCareActivity {
  final String id;
  final String activityType;
  final String description;
  final String status;
  final DateTime? activityDate;
  final List<String> mediaUrls;

  const FamilyCareActivity({
    required this.id,
    required this.activityType,
    required this.description,
    required this.status,
    this.activityDate,
    this.mediaUrls = const [],
  });
}

/// Aggregate for web Care Journal (`/family/updates`).
@immutable
class FamilyCareJournalOverview {
  final List<FamilyCareJournalClient> clients;
  final String selectedClientId;
  final List<FamilyCareJournalDay> days;
  final FamilyMedicalConditions? medicalConditions;
  final List<FamilyMedicationItem> medications;
  final List<FamilyCareMoment> moments;
  final List<FamilyCareActivity> activities;
  final bool medicationsDisabled;
  final bool medicalConditionsDisabled;
  final bool incidentsDisabled;
  final String? medicationsError;
  final String? medicalConditionsError;
  final String footerNote;

  const FamilyCareJournalOverview({
    required this.clients,
    required this.selectedClientId,
    required this.days,
    this.medicalConditions,
    this.medications = const [],
    this.moments = const [],
    this.activities = const [],
    this.medicationsDisabled = false,
    this.medicalConditionsDisabled = false,
    this.incidentsDisabled = false,
    this.medicationsError,
    this.medicalConditionsError,
    this.footerNote =
        'Care notes are verified by the registered duty manager each morning.',
  });

  FamilyCareJournalClient? get selectedClient {
    for (final c in clients) {
      if (c.id == selectedClientId) return c;
    }
    return clients.isEmpty ? null : clients.first;
  }

  List<FamilyDailyUpdateEntry> get allNotes => [
        for (final day in days) ...day.notes,
      ];
}
