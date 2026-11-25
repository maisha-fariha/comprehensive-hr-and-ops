import 'package:flutter/foundation.dart';

/// Shared AI draft text returned by most `/ai/*` review endpoints.
@immutable
class AiDraftResult {
  final String draft;
  final String? note;
  final bool partial;
  final String? model;

  const AiDraftResult({
    required this.draft,
    this.note,
    this.partial = false,
    this.model,
  });
}

@immutable
class AiMarFigure {
  final String medication;
  final bool asNeeded;
  final int given;
  final int refused;
  final int missed;
  final int withheld;
  final int late;

  const AiMarFigure({
    required this.medication,
    this.asNeeded = false,
    this.given = 0,
    this.refused = 0,
    this.missed = 0,
    this.withheld = 0,
    this.late = 0,
  });
}

@immutable
class AiMarReview {
  final String draft;
  final List<AiMarFigure> figures;
  final String? model;

  const AiMarReview({
    required this.draft,
    this.figures = const [],
    this.model,
  });
}

@immutable
class AiGoalSuggestion {
  final String category;
  final String? title;
  final String? description;
  final String? targetDate;
  final String? why;

  const AiGoalSuggestion({
    required this.category,
    this.title,
    this.description,
    this.targetDate,
    this.why,
  });
}

@immutable
class AiGoalsSuggestResult {
  final List<AiGoalSuggestion> suggestions;
  final String? model;

  const AiGoalsSuggestResult({
    this.suggestions = const [],
    this.model,
  });
}

@immutable
class AiRotaFindings {
  final List<String> lines;
  final String draft;
  final String? model;

  const AiRotaFindings({
    required this.draft,
    this.lines = const [],
    this.model,
  });
}

@immutable
class AiTrainingCourseStat {
  final String course;
  final int assigned;
  final int completed;
  final int overdue;
  final int mandatoryOverdue;
  final int dueWithin30Days;
  final int certificatesExpired;

  const AiTrainingCourseStat({
    required this.course,
    this.assigned = 0,
    this.completed = 0,
    this.overdue = 0,
    this.mandatoryOverdue = 0,
    this.dueWithin30Days = 0,
    this.certificatesExpired = 0,
  });
}

@immutable
class AiTrainingPersonGap {
  final String name;
  final List<String> overdue;
  final int mandatory;

  const AiTrainingPersonGap({
    required this.name,
    this.overdue = const [],
    this.mandatory = 0,
  });
}

@immutable
class AiTrainingGaps {
  final String draft;
  final List<AiTrainingCourseStat> courses;
  final List<AiTrainingPersonGap> people;
  final String? model;

  const AiTrainingGaps({
    required this.draft,
    this.courses = const [],
    this.people = const [],
    this.model,
  });
}

@immutable
class AiStockOrderItem {
  final String item;
  final String? unit;
  final num stock;
  final num? daysLeft;
  final num onOrder;
  final num suggestedOrder;
  final bool atOrBelowReorderLevel;

  const AiStockOrderItem({
    required this.item,
    this.unit,
    this.stock = 0,
    this.daysLeft,
    this.onOrder = 0,
    this.suggestedOrder = 0,
    this.atOrBelowReorderLevel = false,
  });
}

@immutable
class AiStockReorder {
  final String draft;
  final List<AiStockOrderItem> items;
  final String? model;

  const AiStockReorder({
    required this.draft,
    this.items = const [],
    this.model,
  });
}

/// One citation from web AI Day Assistant (`POST /ai/daily-logs/ask-day`).
@immutable
class AiAskDaySource {
  final String type;
  final String label;
  final String? time;

  const AiAskDaySource({
    required this.type,
    required this.label,
    this.time,
  });
}

/// Web AI Day Assistant answer payload.
@immutable
class AiAskDayAnswer {
  final String answer;
  final List<AiAskDaySource> sources;
  final List<String> needsAttention;
  /// `answered` | `partly` | `not_recorded`
  final String status;
  final List<String> notIncluded;
  final String? day;
  final String? answeredAt;

  const AiAskDayAnswer({
    required this.answer,
    this.sources = const [],
    this.needsAttention = const [],
    this.status = 'answered',
    this.notIncluded = const [],
    this.day,
    this.answeredAt,
  });
}

@immutable
class AiDailyLogDraftFlag {
  final String category;
  final String note;

  const AiDailyLogDraftFlag({required this.category, required this.note});
}

@immutable
class AiDailyLogDraftObservations {
  final String? mood;
  final String? sleep;
  final String? hygiene;
  final String? meals;
  final String? activities;
  final String? behaviorNotes;
  final String? appointmentNotes;
  final String? wellness;

  const AiDailyLogDraftObservations({
    this.mood,
    this.sleep,
    this.hygiene,
    this.meals,
    this.activities,
    this.behaviorNotes,
    this.appointmentNotes,
    this.wellness,
  });
}

/// One outstanding job from web "Draft handover note".
@immutable
class AiHandoverDraftAction {
  final String title;

  /// `normal` | `important` | `urgent`.
  final String priority;

  const AiHandoverDraftAction({
    required this.title,
    this.priority = 'normal',
  });
}

/// Resident block from web "Draft handover note".
@immutable
class AiHandoverClientUpdate {
  final String clientId;
  final String clientName;

  /// `stable` | `needs_attention` | `urgent`.
  final String status;
  final Map<String, String> health;
  final Map<String, String> medication;
  final List<String> careCompleted;
  final Map<String, String> care;

  const AiHandoverClientUpdate({
    required this.clientId,
    required this.clientName,
    this.status = 'stable',
    this.health = const {},
    this.medication = const {},
    this.careCompleted = const [],
    this.care = const {},
  });
}

/// Web "Draft handover note" (`POST /ai/handovers/draft`).
@immutable
class AiHandoverDraft {
  final String summary;
  final List<AiHandoverDraftAction> actions;
  final String? flagCategory;
  final String? flagNote;
  final List<AiHandoverClientUpdate> clientUpdates;
  final String? model;

  const AiHandoverDraft({
    required this.summary,
    this.actions = const [],
    this.flagCategory,
    this.flagNote,
    this.clientUpdates = const [],
    this.model,
  });

  AiHandoverDraft copyWith({String? summary}) => AiHandoverDraft(
        summary: summary ?? this.summary,
        actions: actions,
        flagCategory: flagCategory,
        flagNote: flagNote,
        clientUpdates: clientUpdates,
        model: model,
      );
}

/// Web "Tidy my note" (`POST /ai/daily-logs/draft-entry`).
@immutable
class AiDailyLogDraftEntry {
  final String body;
  final String? time;
  final String? shift;
  final bool? communityOuting;
  final String? outingNotes;
  final bool? wellnessCheckCompleted;
  final bool? bedCheckCompleted;
  final String? remindAt;
  final String? logType;
  final AiDailyLogDraftObservations observations;
  final AiDailyLogDraftFlag? flag;
  final String? model;

  const AiDailyLogDraftEntry({
    required this.body,
    this.time,
    this.shift,
    this.communityOuting,
    this.outingNotes,
    this.wellnessCheckCompleted,
    this.bedCheckCompleted,
    this.remindAt,
    this.logType,
    this.observations = const AiDailyLogDraftObservations(),
    this.flag,
    this.model,
  });

  AiDailyLogDraftEntry copyWith({String? body}) => AiDailyLogDraftEntry(
        body: body ?? this.body,
        time: time,
        shift: shift,
        communityOuting: communityOuting,
        outingNotes: outingNotes,
        wellnessCheckCompleted: wellnessCheckCompleted,
        bedCheckCompleted: bedCheckCompleted,
        remindAt: remindAt,
        logType: logType,
        observations: observations,
        flag: flag,
        model: model,
      );
}
