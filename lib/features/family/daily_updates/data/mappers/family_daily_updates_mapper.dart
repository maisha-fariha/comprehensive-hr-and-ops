import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_daily_update_entry.dart';
import '../../domain/entities/family_daily_update_enums.dart';
import '../../domain/entities/family_daily_updates_overview.dart';

abstract final class FamilyDailyUpdatesMapper {
  static FamilyDailyUpdatesOverview fromBody(
    dynamic body, {
    FamilyVisibility visibility = FamilyVisibility.unknown,
  }) {
    final entries = <FamilyDailyUpdateEntry>[];
    final items = JsonCodec.unwrapList(body);
    for (var i = 0; i < items.length; i++) {
      if (items[i] is! Map) continue;
      final json = JsonCodec.asMap(items[i] as Map);
      if (!_allowed(json, visibility)) continue;
      final observations = JsonCodec.mapAt(json, 'observations') ?? {};
      final at = JsonCodec.dateTime(json['occurredAt'] ?? json['createdAt']);
      final author = IsoDateRange.personName(
        JsonCodec.mapAt(json, 'author') ?? json['authorName'],
      );
      final hasPhoto = JsonCodec.listAt(json, 'attachments').isNotEmpty ||
          JsonCodec.string(json['photoUrl'] ?? json['imageUrl']) != null;
      if (observations.isEmpty) {
        final category = _categoryFromType(
          json['type'] ?? json['category'] ?? json['title'],
        );
        entries.add(
          _entry(
            json: json,
            category: category,
            title: JsonCodec.stringOr(
              json['title'] ?? json['shift'] ?? json['type'],
              _titleFromCategory(category),
            ),
            description: [
              JsonCodec.string(json['body'] ?? json['summary'] ?? json['notes']),
              if (author != 'Unknown') '— $author',
            ].whereType<String>().join(' '),
            at: at,
            hasPhoto: hasPhoto,
            isLast: false,
          ),
        );
        continue;
      }
      final keys = observations.entries
          .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
          .where((e) => _observationAllowed(e.key, visibility))
          .toList();
      for (final key in keys) {
        entries.add(
          _entry(
            json: json,
            category: _category(key.key),
            title: _title(key.key),
            description: [
              key.value.toString(),
              if (author != 'Unknown') '— $author',
            ].join(' '),
            at: at,
            hasPhoto: hasPhoto,
            isLast: false,
          ),
        );
      }
    }

    for (var i = 0; i < entries.length; i++) {
      entries[i] = FamilyDailyUpdateEntry(
        id: entries[i].id,
        category: entries[i].category,
        timeLabel: entries[i].timeLabel,
        title: entries[i].title,
        description: entries[i].description,
        hasPhoto: entries[i].hasPhoto,
        showTimelineDivider: i != entries.length - 1,
      );
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

  static bool _allowed(Map<String, dynamic> json, FamilyVisibility visibility) {
    final type = (JsonCodec.string(json['type'] ?? json['category']) ?? '')
        .toLowerCase();
    if (type.contains('incident') && !visibility.incidents) return false;
    if (type.contains('med') && !visibility.medications) return false;
    if (type.contains('shift') && !visibility.shiftUpdates) return false;
    if (type.contains('activ') && !visibility.activities) return false;
    return true;
  }

  static bool _observationAllowed(String key, FamilyVisibility visibility) {
    switch (key.toLowerCase()) {
      case 'activities':
        return visibility.activities;
      default:
        return true;
    }
  }

  static FamilyDailyUpdateEntry _entry({
    required Map<String, dynamic> json,
    required DailyUpdateCategory category,
    required String title,
    required String description,
    required DateTime? at,
    required bool hasPhoto,
    required bool isLast,
  }) {
    return FamilyDailyUpdateEntry(
      id: '${JsonCodec.stringOr(json['id'], title)}-$title',
      category: category,
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      title: title,
      description: description.trim(),
      hasPhoto: hasPhoto,
      showTimelineDivider: !isLast,
    );
  }

  static DailyUpdateCategory _categoryFromType(dynamic raw) {
    final text = (raw ?? '').toString().toLowerCase();
    if (text.contains('meal')) return DailyUpdateCategory.meals;
    if (text.contains('activ') || text.contains('outing')) {
      return text.contains('outing')
          ? DailyUpdateCategory.communityOuting
          : DailyUpdateCategory.activities;
    }
    if (text.contains('sleep')) return DailyUpdateCategory.sleep;
    return DailyUpdateCategory.mood;
  }

  static DailyUpdateCategory _category(String key) {
    switch (key.toLowerCase()) {
      case 'meals':
        return DailyUpdateCategory.meals;
      case 'activities':
        return DailyUpdateCategory.activities;
      case 'sleep':
        return DailyUpdateCategory.sleep;
      case 'outing':
      case 'communityouting':
        return DailyUpdateCategory.communityOuting;
      default:
        return DailyUpdateCategory.mood;
    }
  }

  static String _titleFromCategory(DailyUpdateCategory category) {
    switch (category) {
      case DailyUpdateCategory.meals:
        return 'Meals';
      case DailyUpdateCategory.activities:
        return 'Activities';
      case DailyUpdateCategory.sleep:
        return 'Sleep';
      case DailyUpdateCategory.communityOuting:
        return 'Community outing';
      case DailyUpdateCategory.mood:
        return 'Mood';
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
