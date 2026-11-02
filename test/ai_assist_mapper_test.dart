import 'package:comprehensive_hr_and_ops/features/hr/ai/data/mappers/ai_assist_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('draftResultFrom maps summarise/review drafts', () {
    final draft = AiAssistMapper.draftResultFrom({
      'data': {
        'draft': 'Short summary.',
        'partial': true,
        'model': 'claude-opus-5-5',
      },
    });
    expect(draft.draft, 'Short summary.');
    expect(draft.partial, isTrue);
  });

  test('marReviewFrom maps figures and draft', () {
    final review = AiAssistMapper.marReviewFrom({
      'data': {
        'draft': 'Nothing to review.',
        'figures': [
          {
            'medication': 'Paracetamol',
            'asNeeded': true,
            'given': 2,
            'refused': 1,
            'missed': 0,
            'withheld': 0,
            'late': 1,
          },
        ],
        'model': 'claude-opus-5-5',
      },
    });
    expect(review.draft, 'Nothing to review.');
    expect(review.figures.single.medication, 'Paracetamol');
    expect(review.figures.single.asNeeded, isTrue);
    expect(review.figures.single.given, 2);
  });

  test('goalsSuggestFrom maps suggestions', () {
    final result = AiAssistMapper.goalsSuggestFrom({
      'data': {
        'suggestions': [
          {
            'category': 'family_connection',
            'title': 'Call family once a week',
            'description': 'Weekly call',
            'targetDate': '2026-12-28',
            'why': 'From notes',
          },
        ],
      },
    });
    expect(result.suggestions, hasLength(1));
    expect(result.suggestions.single.category, 'family_connection');
    expect(result.suggestions.single.title, 'Call family once a week');
  });

  test('rotaReviewFrom builds finding lines', () {
    final result = AiAssistMapper.rotaReviewFrom({
      'data': {
        'draft': 'Check staffing.',
        'findings': {
          'understaffed': [
            {
              'shift': 'Shift A',
              'required': 4,
              'assigned': 1,
            },
          ],
          'overLimit': [],
          'shortRest': [],
          'training': [
            {
              'name': 'S1',
              'course': 'First aid',
              'issue': 'overdue',
              'date': '2026-10-20',
            },
          ],
        },
      },
    });
    expect(result.draft, 'Check staffing.');
    expect(result.lines.first, contains('Short: Shift A'));
    expect(result.lines.last, contains('Training: S1'));
  });

  test('trainingGapsFrom and stockReorderFrom map tables', () {
    final gaps = AiAssistMapper.trainingGapsFrom({
      'data': {
        'draft': 'Focus on overdue courses.',
        'courses': [
          {
            'course': 'Safeguarding',
            'assigned': 10,
            'completed': 7,
            'overdue': 2,
            'mandatoryOverdue': 1,
            'dueWithin30Days': 3,
            'certificatesExpired': 1,
          },
        ],
        'people': [
          {
            'name': 'S1',
            'overdue': ['Safeguarding'],
            'mandatory': 1,
          },
        ],
      },
    });
    expect(gaps.courses.single.course, 'Safeguarding');
    expect(gaps.people.single.name, 'S1');

    final stock = AiAssistMapper.stockReorderFrom({
      'data': {
        'draft': 'Order gloves.',
        'items': [
          {
            'item': 'Gloves',
            'unit': 'box',
            'stock': 2,
            'daysLeft': 4,
            'onOrder': 0,
            'suggestedOrder': 5,
            'atOrBelowReorderLevel': true,
          },
        ],
      },
    });
    expect(stock.items.single.item, 'Gloves');
    expect(stock.items.single.suggestedOrder, 5);
  });
}
