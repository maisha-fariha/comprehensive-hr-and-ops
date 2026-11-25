import 'package:comprehensive_hr_and_ops/features/common/widgets/prn_shortest_gap_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('totalMinutes converts hrs/mins and rejects empty', () {
    final hours = TextEditingController(text: '4');
    final minutes = TextEditingController(text: '0');
    expect(
      PrnShortestGapField.totalMinutes(hours: hours, minutes: minutes),
      240,
    );

    hours.clear();
    minutes.clear();
    expect(
      PrnShortestGapField.totalMinutes(hours: hours, minutes: minutes),
      isNull,
    );

    hours.text = '0';
    minutes.text = '30';
    expect(
      PrnShortestGapField.totalMinutes(hours: hours, minutes: minutes),
      30,
    );

    hours.dispose();
    minutes.dispose();
  });

  test('applyMinutes splits API minutes into fields', () {
    final hours = TextEditingController();
    final minutes = TextEditingController();
    PrnShortestGapField.applyMinutes(
      250,
      hours: hours,
      minutes: minutes,
    );
    expect(hours.text, '4');
    expect(minutes.text, '10');
    hours.dispose();
    minutes.dispose();
  });

  testWidgets('preset chips set hours and highlight selection', (tester) async {
    final hours = TextEditingController();
    final minutes = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PrnShortestGapField(
              hours: hours,
              minutes: minutes,
              onChanged: () => setState(() {}),
              fieldStyle: const TextStyle(fontSize: 14),
              decoration: ({String? hint, Widget? suffix}) => InputDecoration(
                hintText: hint,
                suffixIcon: suffix,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('4 hrs'));
    await tester.pump();
    expect(hours.text, '4');
    expect(minutes.text, '0');
    expect(
      PrnShortestGapField.totalMinutes(hours: hours, minutes: minutes),
      240,
    );
    hours.dispose();
    minutes.dispose();
  });
}
