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

  static List<dynamic> _list(dynamic raw) => raw is List ? raw : const [];

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
