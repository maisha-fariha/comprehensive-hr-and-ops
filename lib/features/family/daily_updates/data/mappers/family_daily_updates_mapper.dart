import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/family_daily_update_entry.dart';
import '../../domain/entities/family_daily_update_enums.dart';
import '../../domain/entities/family_daily_updates_overview.dart';

abstract final class FamilyDailyUpdatesMapper {
  static FamilyDailyUpdatesOverview fromBody(dynamic body) {
    final entries = <FamilyDailyUpdateEntry>[];
    final items = JsonCodec.unwrapList(body);
    for (var i = 0; i < items.length; i++) {
      if (items[i] is! Map) continue;
      final json = JsonCodec.asMap(items[i] as Map);
      final observations = JsonCodec.mapAt(json, 'observations') ?? {};
      final at = JsonCodec.dateTime(json['occurredAt'] ?? json['createdAt']);
      final author = IsoDateRange.personName(
        JsonCodec.mapAt(json, 'author') ?? json['authorName'],
      );
      if (observations.isEmpty) {
        entries.add(
          _entry(
            json: json,
            category: DailyUpdateCategory.mood,
            title: JsonCodec.stringOr(json['title'] ?? json['shift'], 'Update'),
            description: [
              JsonCodec.string(json['body'] ?? json['summary']),
              if (author != 'Unknown') '— $author',
            ].whereType<String>().join(' '),
            at: at,
            isLast: i == items.length - 1,
          ),
        );
        continue;
      }
      final keys = observations.entries
          .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
          .toList();
      for (var k = 0; k < keys.length; k++) {
        entries.add(
          _entry(
            json: json,
            category: _category(keys[k].key),
            title: _title(keys[k].key),
            description: [
              keys[k].value.toString(),
              if (author != 'Unknown') '— $author',
            ].join(' '),
            at: at,
            isLast: i == items.length - 1 && k == keys.length - 1,
          ),
        );
      }
    }

    final now = DateTime.now();
    return FamilyDailyUpdatesOverview(
      screenTitle: 'Daily Updates',
      screenSubtitle: 'Only approved updates are shown.',
      dateSectionLabel: 'Today · ${IsoDateRange.formatMonthDay(now)}',
      entries: entries,
      footerNote:
          'All updates are reviewed and approved by the care team before sharing.',
    );
  }

  static FamilyDailyUpdateEntry _entry({
    required Map<String, dynamic> json,
    required DailyUpdateCategory category,
    required String title,
    required String description,
    required DateTime? at,
    required bool isLast,
  }) {
    return FamilyDailyUpdateEntry(
      id: '${JsonCodec.stringOr(json['id'], title)}-$title',
      category: category,
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      title: title,
      description: description.trim(),
      showTimelineDivider: !isLast,
    );
  }

  static DailyUpdateCategory _category(String key) {
    switch (key.toLowerCase()) {
      case 'meals':
        return DailyUpdateCategory.meals;
      case 'activities':
        return DailyUpdateCategory.activities;
      case 'sleep':
        return DailyUpdateCategory.sleep;
      default:
        return DailyUpdateCategory.mood;
    }
  }

  static String _title(String key) {
    switch (key.toLowerCase()) {
      case 'meals':
        return 'Meals';
      case 'activities':
        return 'Activities';
      case 'sleep':
        return 'Sleep';
      case 'hygiene':
        return 'Hygiene';
      case 'behaviornotes':
      case 'behavior':
        return 'Behavior';
      case 'wellness':
        return 'Wellness';
      default:
        return 'Mood';
    }
  }

  const FamilyDailyUpdatesMapper._();
}
