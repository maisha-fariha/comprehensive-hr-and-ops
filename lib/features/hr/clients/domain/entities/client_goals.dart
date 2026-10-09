import 'package:flutter/foundation.dart';

/// One standard goal area from `GET /client-goals/categories`.
@immutable
class ClientGoalCategory {
  final String key;
  final String label;

  const ClientGoalCategory({required this.key, required this.label});
}

/// A resident goal from `GET /clients/{id}/goals`.
@immutable
class ClientGoal {
  final String id;
  final String category;
  final String categoryLabel;
  final String title;
  final bool isCustom;
  final String? targetDate;

  /// `active`, `achieved` or `discontinued`.
  final String status;

  const ClientGoal({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.title,
    this.isCustom = false,
    this.targetDate,
    this.status = 'active',
  });

  bool get isActive => status == 'active';
}

/// One reporting window of `GET /clients/{id}/goals/outcomes`.
@immutable
class GoalPeriod {
  final int logged;
  final int achieved;
  final int? progress;
  final int? independence;

  /// `upward`, `downward` or `steady`.
  final String trend;

  const GoalPeriod({
    this.logged = 0,
    this.achieved = 0,
    this.progress,
    this.independence,
    this.trend = 'steady',
  });
}

/// Week, month and whole-stay progress.
@immutable
class GoalPeriods {
  final GoalPeriod weekly;
  final GoalPeriod monthly;
  final GoalPeriod discharge;

  const GoalPeriods({
    this.weekly = const GoalPeriod(),
    this.monthly = const GoalPeriod(),
    this.discharge = const GoalPeriod(),
  });
}

/// `GET /clients/{id}/goals/outcomes`: overall plus per-goal progress.
@immutable
class ClientGoalOutcomes {
  final GoalPeriods overall;
  final Map<String, GoalPeriods> byGoal;

  const ClientGoalOutcomes({
    this.overall = const GoalPeriods(),
    this.byGoal = const {},
  });
}

/// How much help the resident needed (`assistanceLevel`).
enum GoalAssistance {
  independent('independent', 'Independent'),
  verbalPrompt('verbal_prompt', 'Verbal prompt'),
  physicalAssist('physical_assist', 'Physical assist'),
  notApplicable('not_applicable', 'Not applicable');

  final String value;
  final String label;

  const GoalAssistance(this.value, this.label);

  static GoalAssistance parse(String? value) => GoalAssistance.values.firstWhere(
        (a) => a.value == value,
        orElse: () => GoalAssistance.independent,
      );
}

/// One day's check-off from `GET /clients/{id}/goals/logs`.
@immutable
class ClientGoalLog {
  final String id;
  final String goalId;
  final String? staffId;
  final String logDate;
  final bool achieved;
  final GoalAssistance assistance;
  final String notes;

  const ClientGoalLog({
    required this.id,
    required this.goalId,
    required this.logDate,
    this.staffId,
    this.achieved = false,
    this.assistance = GoalAssistance.independent,
    this.notes = '',
  });
}
