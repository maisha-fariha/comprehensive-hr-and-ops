import 'package:comprehensive_hr_and_ops/features/hr/scheduling/domain/entities/create_shift_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateShiftRestOverride', () {
    test('matches web min-length copy', () {
      expect(
        CreateShiftRestOverride.validationError('hh', submitted: true),
        'At least 10 characters required (8 more needed).',
      );
      expect(
        CreateShiftRestOverride.validationError('hfnf hfm', submitted: true),
        'At least 10 characters required (2 more needed).',
      );
      expect(
        CreateShiftRestOverride.validationError(
          'Emergency cover',
          submitted: true,
        ),
        isNull,
      );
      expect(
        CreateShiftRestOverride.validationError('', submitted: false),
        isNull,
      );
      expect(
        CreateShiftRestOverride.validationError('', submitted: true),
        'At least 10 characters required (10 more needed).',
      );
    });

    test('matches web counter label', () {
      expect(
        CreateShiftRestOverride.counterLabel('hfnf hfm'),
        '8/500 chars • 2 words',
      );
      expect(
        CreateShiftRestOverride.counterLabel(''),
        '0/500 chars • 0 words',
      );
    });

    test('recognises Zod min-length API copy', () {
      expect(
        CreateShiftRestOverride.matchesApiMinLengthMessage(
          'String must contain at least 10 character(s)',
        ),
        isTrue,
      );
    });
  });
}
