import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_care_journal_models.dart';
import '../../domain/entities/family_daily_update_entry.dart';
import '../../domain/entities/family_daily_update_enums.dart';
import '../../domain/entities/family_daily_updates_overview.dart';

abstract final class FamilyDailyUpdatesMapper {
  /// Legacy shape used by older callers — flattens care-journal days.
  static FamilyDailyUpdatesOverview fromBody(
    dynamic body, {
    FamilyVisibility visibility = FamilyVisibility.unknown,
  }) {
    final journal = careJournalFrom(
      clientsBody: const [],
      dailyUpdatesBody: body,
      visibility: visibility,
    );
    final now = DateTime.now();
    return FamilyDailyUpdatesOverview(
      screenTitle: 'Care Journal',
      screenSubtitle:
          'A transparent view of daily routines, nourishment, physical wellbeing, and moments.',
      dateSectionLabel: 'Today · ${IsoDateRange.formatMonthDay(now)}',
      entries: journal.allNotes,
      footerNote: journal.footerNote,
    );
  }

  static FamilyCareJournalOverview careJournalFrom({
    required dynamic clientsBody,
    required dynamic dailyUpdatesBody,
    dynamic medicalConditionsBody,
    dynamic medicationsBody,
    dynamic momentsBody,
    dynamic activitiesBody,
    String? selectedClientId,
    FamilyVisibility visibility = FamilyVisibility.unknown,
    bool medicationsDisabled = false,
    bool medicalConditionsDisabled = false,
    String? medicationsError,
    String? medicalConditionsError,
  }) {
    final clients = _clients(clientsBody);
    final selected = () {
      final want = (selectedClientId ?? '').trim();
      if (want.isNotEmpty) {
        for (final c in clients) {
          if (c.id == want) return want;
        }
      }
      return clients.isEmpty ? '' : clients.first.id;
    }();

    final days = _days(dailyUpdatesBody, visibility);
    return FamilyCareJournalOverview(
      clients: clients,
      selectedClientId: selected,
      days: days,
      medicalConditions: medicalConditionsDisabled
          ? null
          : _conditions(medicalConditionsBody),
      medications:
          medicationsDisabled ? const [] : _medications(medicationsBody),
      moments: _moments(momentsBody),
      activities: _activities(activitiesBody),
      medicationsDisabled: medicationsDisabled,
      medicalConditionsDisabled: medicalConditionsDisabled,
      medicationsError: medicationsError,
      medicalConditionsError: medicalConditionsError,
    );
  }

  static List<FamilyCareJournalClient> _clients(dynamic body) {
    final rows = body is List ? body : JsonCodec.unwrapList(body);
    return [
      for (final row in rows.whereType<Map>())
        () {
          final m = JsonCodec.asMap(row);
          final vis = JsonCodec.mapAt(m, 'visibility') ?? {};
          final name = IsoDateRange.personName(
            m['name'] ??
                {
                  'firstName': m['firstName'],
                  'lastName': m['lastName'],
                },
          );
          return FamilyCareJournalClient(
            id: JsonCodec.stringOr(m['id'], ''),
            name: name == 'Unknown' ? 'Resident' : name,
            activities: JsonCodec.boolean(vis['activities']) ?? true,
            incidents: JsonCodec.boolean(vis['incidents']) ?? false,
            medications: JsonCodec.boolean(vis['medications']) ?? false,
            medicalConditions:
                JsonCodec.boolean(vis['medicalConditions']) ?? false,
            documents: JsonCodec.boolean(vis['documents']) ?? false,
            appointments: JsonCodec.boolean(vis['appointments']) ?? true,
            messages: JsonCodec.boolean(vis['messages']) ?? true,
          );
        }(),
    ].where((c) => c.id.isNotEmpty).toList();
  }

  static List<FamilyCareJournalDay> _days(
    dynamic body,
    FamilyVisibility visibility,
  ) {
    final rows = JsonCodec.unwrapList(body);
    final days = <FamilyCareJournalDay>[];
    for (final row in rows.whereType<Map>()) {
      final day = JsonCodec.asMap(row);
      final logDate = JsonCodec.dateTime(day['logDate'] ?? day['date']);
      final notes = <FamilyDailyUpdateEntry>[];

      final entries = JsonCodec.listAt(day, 'entries');
      for (final raw in entries.whereType<Map>()) {
        final entry = JsonCodec.asMap(raw);
        final at = JsonCodec.dateTime(
          entry['occurredAt'] ?? entry['createdAt'],
        );
        final author = IsoDateRange.personName(
          JsonCodec.mapAt(entry, 'author') ?? entry['authorName'],
        );
        final bodyText = JsonCodec.stringOr(
          entry['body'] ?? entry['notes'] ?? entry['summary'],
          '',
        ).trim();
        if (bodyText.isEmpty) continue;
        notes.add(
          FamilyDailyUpdateEntry(
            id: JsonCodec.stringOr(entry['id'], '${day['id']}-$at'),
            category: DailyUpdateCategory.mood,
            timeLabel: at == null ? '' : IsoDateRange.timeLabel(at),
            title: 'Care Note',
            description: bodyText,
            authorName: author == 'Unknown' ? null : author,
            hasPhoto: false,
            showTimelineDivider: true,
          ),
        );
      }

      final activities = JsonCodec.listAt(day, 'activities');
      if (visibility.activities) {
        for (final raw in activities.whereType<Map>()) {
          final activity = JsonCodec.asMap(raw);
          final media = [
            for (final u in JsonCodec.listAt(activity, 'mediaUrls'))
              if (u != null && '$u'.trim().isNotEmpty) '$u'.trim(),
          ];
          final description = JsonCodec.stringOr(
            activity['description'] ?? activity['body'],
            'Activity update',
          );
          final at = JsonCodec.dateTime(activity['occurredAt']);
          notes.add(
            FamilyDailyUpdateEntry(
              id: JsonCodec.stringOr(activity['id'], description),
              category: DailyUpdateCategory.activities,
              timeLabel: at == null ? '' : IsoDateRange.timeLabel(at),
              title: _activityTitle(
                JsonCodec.stringOr(activity['activityType'], 'Activity'),
              ),
              description: description,
              hasPhoto: media.isNotEmpty,
              mediaUrls: media,
              showTimelineDivider: true,
            ),
          );
        }
      }

      // Flat legacy rows (single entry objects without nested `entries`).
      if (notes.isEmpty &&
          day['body'] != null &&
          '${day['body']}'.trim().isNotEmpty) {
        final at = JsonCodec.dateTime(day['occurredAt'] ?? day['createdAt']);
        notes.add(
          FamilyDailyUpdateEntry(
            id: JsonCodec.stringOr(day['id'], 'note'),
            category: DailyUpdateCategory.mood,
            timeLabel: at == null ? '' : IsoDateRange.timeLabel(at),
            title: 'Care Note',
            description: '${day['body']}'.trim(),
            hasPhoto: false,
            showTimelineDivider: true,
          ),
        );
      }

      if (notes.isEmpty && activities.isEmpty) {
        // Keep empty days that only have media so the date section still shows.
        final media = [
          for (final u in JsonCodec.listAt(day, 'mediaUrls'))
            if (u != null && '$u'.trim().isNotEmpty) '$u'.trim(),
        ];
        if (media.isEmpty) continue;
      }

      for (var i = 0; i < notes.length; i++) {
        notes[i] = FamilyDailyUpdateEntry(
          id: notes[i].id,
          category: notes[i].category,
          timeLabel: notes[i].timeLabel,
          title: notes[i].title,
          description: notes[i].description,
          authorName: notes[i].authorName,
          hasPhoto: notes[i].hasPhoto,
          mediaUrls: notes[i].mediaUrls,
          showTimelineDivider: i != notes.length - 1,
        );
      }

      final careNoteCount = notes
          .where((n) => n.category != DailyUpdateCategory.activities)
          .length;
      days.add(
        FamilyCareJournalDay(
          id: JsonCodec.stringOr(day['id'], '${logDate ?? days.length}'),
          logDate: logDate,
          dateLabel: logDate == null
              ? 'Care day'
              : IsoDateRange.formatDisplayDate(logDate),
          notes: notes,
          careNoteCount: careNoteCount,
          activityCount: activities.length,
          mediaUrls: [
            for (final u in JsonCodec.listAt(day, 'mediaUrls'))
              if (u != null && '$u'.trim().isNotEmpty) '$u'.trim(),
          ],
        ),
      );
    }
    return days;
  }

  static String _activityTitle(String type) {
    final t = type.toLowerCase();
    if (t.contains('family_memory') || t.contains('memory')) {
      return 'Family memory';
    }
    if (t.contains('outing')) return 'Community Outing';
    return 'Activity';
  }

  static FamilyMedicalConditions? _conditions(dynamic body) {
    if (body == null) return null;
    final map = body is Map
        ? JsonCodec.asMap(body)
        : JsonCodec.unwrapMap(body);
    if (map.isEmpty) return const FamilyMedicalConditions();
    List<String> listOf(dynamic raw) {
      if (raw is List) {
        return [
          for (final item in raw)
            if ('$item'.trim().isNotEmpty) '$item'.trim(),
        ];
      }
      final text = JsonCodec.string(raw);
      if (text == null || text.trim().isEmpty) return const [];
      return [text.trim()];
    }

    return FamilyMedicalConditions(
      diagnoses: listOf(map['diagnoses'] ?? map['diagnosis']),
      allergies: listOf(map['allergies'] ?? map['allergy']),
      dietaryRequirements: JsonCodec.string(
        map['dietaryRequirements'] ?? map['dietaryTexture'] ?? map['diet'],
      ),
    );
  }

  static List<FamilyMedicationItem> _medications(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    return [
      for (final row in rows.whereType<Map>())
        () {
          final m = JsonCodec.asMap(row);
          final times = [
            for (final t in JsonCodec.listAt(m, 'scheduleTimes'))
              if (t != null && '$t'.trim().isNotEmpty) '$t'.trim(),
          ];
          return FamilyMedicationItem(
            id: JsonCodec.stringOr(m['id'], m['name'] ?? 'med'),
            name: JsonCodec.stringOr(m['name'], 'Medication'),
            dose: JsonCodec.stringOr(m['dose'], ''),
            route: JsonCodec.stringOr(m['route'], ''),
            frequency: JsonCodec.stringOr(
              m['scheduleFrequency'] ?? m['frequency'],
              '',
            ),
            times: times,
          );
        }(),
    ];
  }

  static List<FamilyCareMoment> _moments(dynamic body) {
    final rows = body is List ? body : JsonCodec.unwrapList(body);
    return [
      for (final row in rows.whereType<Map>())
        () {
          final m = JsonCodec.asMap(row);
          final url = JsonCodec.stringOr(
            m['url'] ?? m['fileUrl'] ?? m['photoUrl'],
            '',
          );
          if (url.isEmpty) return null;
          return FamilyCareMoment(
            url: url,
            activityId: JsonCodec.string(m['activityId']),
            activityType: JsonCodec.stringOr(m['activityType'], ''),
            description: JsonCodec.stringOr(
              m['description'] ?? m['caption'],
              'Shared moment',
            ),
            takenOn: JsonCodec.dateTime(
              m['takenOn'] ?? m['occurredAt'] ?? m['activityDate'],
            ),
          );
        }(),
    ].whereType<FamilyCareMoment>().toList();
  }

  static List<FamilyCareActivity> _activities(dynamic body) {
    final rows = JsonCodec.unwrapList(body);
    return [
      for (final row in rows.whereType<Map>())
        () {
          final m = JsonCodec.asMap(row);
          return FamilyCareActivity(
            id: JsonCodec.stringOr(m['id'], ''),
            activityType: JsonCodec.stringOr(m['activityType'], 'activity'),
            description: JsonCodec.stringOr(m['description'], ''),
            status: JsonCodec.stringOr(m['status'], ''),
            activityDate: JsonCodec.dateTime(
              m['activityDate'] ?? m['occurredAt'],
            ),
            mediaUrls: [
              for (final u in JsonCodec.listAt(m, 'mediaUrls'))
                if (u != null && '$u'.trim().isNotEmpty) '$u'.trim(),
            ],
          );
        }(),
    ].where((a) => a.id.isNotEmpty).toList();
  }

  const FamilyDailyUpdatesMapper._();
}
