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
