import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/ai_assist.dart';

abstract final class AiAssistMapper {
  static AiDraftResult draftResultFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    return AiDraftResult(
      draft: JsonCodec.stringOr(json['draft'], ''),
      partial: json['partial'] == true,
      model: JsonCodec.string(json['model']),
    );
  }

  static AiMarReview marReviewFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final figures = <AiMarFigure>[];
    final raw = json['figures'];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final map = JsonCodec.asMap(item);
        figures.add(
          AiMarFigure(
            medication: JsonCodec.stringOr(map['medication'], ''),
            asNeeded: map['asNeeded'] == true,
            given: _int(map['given']),
            refused: _int(map['refused']),
            missed: _int(map['missed']),
            withheld: _int(map['withheld']),
            late: _int(map['late']),
          ),
        );
      }
    }
    return AiMarReview(
      draft: JsonCodec.stringOr(json['draft'], ''),
      figures: figures,
      model: JsonCodec.string(json['model']),
    );
  }

  static AiGoalsSuggestResult goalsSuggestFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final suggestions = <AiGoalSuggestion>[];
    final raw = json['suggestions'];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final map = JsonCodec.asMap(item);
        final category = JsonCodec.string(map['category'])?.trim();
        if (category == null || category.isEmpty) continue;
        suggestions.add(
          AiGoalSuggestion(
            category: category,
            title: JsonCodec.string(map['title']),
            description: JsonCodec.string(map['description']),
            targetDate: JsonCodec.string(map['targetDate']),
            why: JsonCodec.string(map['why']),
          ),
        );
      }
    }
    return AiGoalsSuggestResult(
      suggestions: suggestions,
      model: JsonCodec.string(json['model']),
    );
  }

  static AiRotaFindings rotaReviewFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final findings = JsonCodec.mapAt(json, 'findings') ?? const {};
    final lines = <String>[
      for (final item in _list(findings['understaffed']))
        if (item is Map)
          'Short: ${JsonCodec.stringOr(item['shift'], 'shift')} — '
              '${_int(item['assigned'])} of ${_int(item['required'])}',
      for (final item in _list(findings['overLimit']))
        if (item is Map)
          'Over limit: ${JsonCodec.stringOr(item['name'], 'staff')}, '
              'week of ${JsonCodec.stringOr(item['weekStarting'], '—')} — '
              '${item['hours']} h (limit ${item['limit']})',
      for (final item in _list(findings['shortRest']))
        if (item is Map)
          'Short rest: ${JsonCodec.stringOr(item['name'], 'staff')}, '
              '${JsonCodec.stringOr(item['endedAt'], '—')} → '
              '${JsonCodec.stringOr(item['nextStartsAt'], '—')} '
              '(${item['restHours']} h)',
      for (final item in _list(findings['training']))
        if (item is Map)
          'Training: ${JsonCodec.stringOr(item['name'], 'staff')} — '
              '${JsonCodec.stringOr(item['course'], 'course')}, '
              '${JsonCodec.stringOr(item['issue'], 'issue')}'
              '${JsonCodec.string(item['date']) == null ? '' : ' (${item['date']})'}',
    ];
    return AiRotaFindings(
      draft: JsonCodec.stringOr(json['draft'], ''),
      lines: lines,
      model: JsonCodec.string(json['model']),
    );
  }

  static AiTrainingGaps trainingGapsFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final courses = <AiTrainingCourseStat>[];
    for (final item in _list(json['courses'])) {
      if (item is! Map) continue;
      final map = JsonCodec.asMap(item);
      courses.add(
        AiTrainingCourseStat(
          course: JsonCodec.stringOr(map['course'], ''),
          assigned: _int(map['assigned']),
          completed: _int(map['completed']),
          overdue: _int(map['overdue']),
          mandatoryOverdue: _int(map['mandatoryOverdue']),
          dueWithin30Days: _int(map['dueWithin30Days']),
          certificatesExpired: _int(map['certificatesExpired']),
        ),
      );
    }
    final people = <AiTrainingPersonGap>[];
    for (final item in _list(json['people'])) {
      if (item is! Map) continue;
      final map = JsonCodec.asMap(item);
      people.add(
        AiTrainingPersonGap(
          name: JsonCodec.stringOr(map['name'], ''),
          overdue: [
            for (final o in _list(map['overdue']))
              if ((JsonCodec.string(o) ?? o.toString()).trim().isNotEmpty)
                (JsonCodec.string(o) ?? o.toString()).trim(),
          ],
          mandatory: _int(map['mandatory']),
        ),
      );
    }
    return AiTrainingGaps(
      draft: JsonCodec.stringOr(json['draft'], ''),
      courses: courses,
      people: people,
      model: JsonCodec.string(json['model']),
    );
  }

  static AiStockReorder stockReorderFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final items = <AiStockOrderItem>[];
    for (final item in _list(json['items'])) {
      if (item is! Map) continue;
      final map = JsonCodec.asMap(item);
      items.add(
        AiStockOrderItem(
          item: JsonCodec.stringOr(map['item'], ''),
          unit: JsonCodec.string(map['unit']),
          stock: _num(map['stock']),
          daysLeft: map['daysLeft'] == null ? null : _num(map['daysLeft']),
          onOrder: _num(map['onOrder']),
          suggestedOrder: _num(map['suggestedOrder']),
          atOrBelowReorderLevel: map['atOrBelowReorderLevel'] == true,
        ),
      );
    }
    return AiStockReorder(
      draft: JsonCodec.stringOr(json['draft'], ''),
      items: items,
      model: JsonCodec.string(json['model']),
    );
  }

  static AiAskDayAnswer askDayFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final sources = <AiAskDaySource>[];
    for (final item in _list(json['sources'])) {
      if (item is! Map) continue;
      final map = JsonCodec.asMap(item);
      final type = JsonCodec.stringOr(map['type'], '');
      final label = JsonCodec.stringOr(map['label'], '');
      if (type.isEmpty && label.isEmpty) continue;
      sources.add(
        AiAskDaySource(
          type: type,
          label: label,
          time: JsonCodec.string(map['time']),
        ),
      );
    }
    final status = JsonCodec.stringOr(json['status'], 'answered');
    return AiAskDayAnswer(
      answer: JsonCodec.stringOr(json['answer'], ''),
      sources: sources,
      needsAttention: _strings(json['needsAttention']),
      status: status.isEmpty ? 'answered' : status,
      notIncluded: _strings(json['notIncluded']),
      day: JsonCodec.string(json['day']),
      answeredAt: JsonCodec.string(json['answeredAt']),
    );
  }

  static const _jobPriorities = {'normal', 'important', 'urgent'};
  static const _clientStatuses = {'stable', 'needs_attention', 'urgent'};
  static const _careCompleted = {
    'personal_care',
    'feeding',
    'mobility_assistance',
    'hygiene',
  };

  /// Web `POST /ai/handovers/draft`.
  static AiHandoverDraft handoverDraftFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final actions = <AiHandoverDraftAction>[];
    final actionsRaw = json['actions'];
    if (actionsRaw is List && actionsRaw.isNotEmpty) {
      for (final item in actionsRaw) {
        if (item is! Map) continue;
        final map = JsonCodec.asMap(item);
        final title = JsonCodec.string(map['title'])?.trim() ?? '';
        if (title.isEmpty) continue;
        final priority = JsonCodec.stringOr(map['priority'], 'normal');
        actions.add(
          AiHandoverDraftAction(
            title: title,
            priority: _jobPriorities.contains(priority) ? priority : 'normal',
          ),
        );
      }
    } else {
      for (final title in _strings(json['pendingActions'])) {
        actions.add(AiHandoverDraftAction(title: title));
      }
    }
    final flagRaw = JsonCodec.mapAt(json, 'flag');
    final flagCategory = flagRaw == null
        ? null
        : JsonCodec.string(flagRaw['category'])?.trim();
    final clientUpdates = <AiHandoverClientUpdate>[];
    final clientsRaw = json['clientUpdates'];
    if (clientsRaw is List) {
      for (final item in clientsRaw) {
        if (item is! Map) continue;
        final map = JsonCodec.asMap(item);
        final clientId = JsonCodec.string(map['clientId'])?.trim() ?? '';
        if (clientId.isEmpty) continue;
        final status = JsonCodec.stringOr(map['status'], 'stable');
        final careRaw = JsonCodec.mapAt(map, 'care') ?? const {};
        final completed = <String>[
          for (final value in _strings(careRaw['completed']))
            if (_careCompleted.contains(value)) value,
        ];
        clientUpdates.add(
          AiHandoverClientUpdate(
            clientId: clientId,
            clientName: JsonCodec.stringOr(map['clientName'], 'Resident'),
            status: _clientStatuses.contains(status) ? status : 'stable',
            health: _stringMap(JsonCodec.mapAt(map, 'health')),
            medication: _stringMap(JsonCodec.mapAt(map, 'medication')),
            careCompleted: completed,
            care: {
              for (final key in const [
                'otherCompleted',
                'pending',
                'followUpRequired',
              ])
                if ((JsonCodec.string(careRaw[key]) ?? '').trim().isNotEmpty)
                  key: JsonCodec.string(careRaw[key])!.trim(),
            },
          ),
        );
      }
    }
    return AiHandoverDraft(
      summary: JsonCodec.stringOr(json['summary'], ''),
      actions: actions,
      flagCategory:
          flagCategory == null || flagCategory.isEmpty ? null : flagCategory,
      flagNote: flagRaw == null ? null : JsonCodec.string(flagRaw['note']),
      clientUpdates: clientUpdates,
      model: JsonCodec.string(json['model']),
    );
  }

  static Map<String, String> _stringMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const {};
    final out = <String, String>{};
    for (final entry in raw.entries) {
      final value = JsonCodec.string(entry.value)?.trim() ?? '';
      if (value.isEmpty) continue;
      out[entry.key] = value;
    }
    return out;
  }

  static AiDailyLogDraftEntry dailyLogDraftFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final obsRaw = JsonCodec.mapAt(json, 'observations') ?? const {};
    final flagRaw = JsonCodec.mapAt(json, 'flag');
    return AiDailyLogDraftEntry(
      body: JsonCodec.stringOr(json['body'], ''),
      time: JsonCodec.string(json['time']),
      shift: JsonCodec.string(json['shift']),
      communityOuting: json['communityOuting'] is bool
          ? json['communityOuting'] as bool
          : null,
      outingNotes: JsonCodec.string(json['outingNotes']),
      wellnessCheckCompleted: json['wellnessCheckCompleted'] == true
          ? true
          : null,
      bedCheckCompleted:
          json['bedCheckCompleted'] == true ? true : null,
      remindAt: JsonCodec.string(json['remindAt']),
      logType: JsonCodec.string(json['logType']),
      observations: AiDailyLogDraftObservations(
        mood: JsonCodec.string(obsRaw['mood']),
        sleep: JsonCodec.string(obsRaw['sleep']),
        hygiene: JsonCodec.string(obsRaw['hygiene']),
        meals: JsonCodec.string(obsRaw['meals']),
        activities: JsonCodec.string(obsRaw['activities']),
        behaviorNotes: JsonCodec.string(obsRaw['behaviorNotes']),
        appointmentNotes: JsonCodec.string(obsRaw['appointmentNotes']),
        wellness: JsonCodec.string(obsRaw['wellness']),
      ),
      flag: flagRaw == null
          ? null
          : AiDailyLogDraftFlag(
              category: JsonCodec.stringOr(flagRaw['category'], ''),
              note: JsonCodec.stringOr(flagRaw['note'], ''),
            ),
      model: JsonCodec.string(json['model']),
    );
  }

  static List<dynamic> _list(dynamic raw) => raw is List ? raw : const [];

  static List<String> _strings(dynamic raw) => [
        for (final item in _list(raw))
          if ('$item'.trim().isNotEmpty) '$item'.trim(),
      ];

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static num _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse('$value') ?? 0;
  }

  const AiAssistMapper._();
}
