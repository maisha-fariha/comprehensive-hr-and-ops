import 'package:comprehensive_hr_and_ops/core/widgets/form_scroll_to_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scrollToFirstFormError moves to the topmost invalid field', (
    tester,
  ) async {
    final controller = ScrollController();
    late BuildContext formContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    formContext = context;
                    return SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        children: [
                          for (var i = 0; i < 12; i++)
                            FormFieldAnchor(
                              field: 'f$i',
                              child: SizedBox(
                                height: 140,
                                child: Text('Field $i'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              TextButton(
                key: const ValueKey('trigger'),
                onPressed: () {
                  scrollToFirstFormError(
                    formContext,
                    errors: const {
                      'f8': 'Required',
                      'f3': 'Required',
                    },
                    fieldKeys: {
                      for (var i = 0; i < 12; i++)
                        'f$i': FormFieldAnchor.keyFor('f$i'),
                    },
                  );
                },
                child: const Text('Validate'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(controller.offset, 0);
    await tester.tap(find.byKey(const ValueKey('trigger')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
    final field = find.byKey(FormFieldAnchor.keyFor('f3'));
    final box = tester.renderObject<RenderBox>(field);
    final topLeft = box.localToGlobal(Offset.zero);
    expect(topLeft.dy, lessThan(220));
  });

  testWidgets('scrollToFirstFormError no-ops when errors are empty', (
    tester,
  ) async {
    final controller = ScrollController();
    late BuildContext formContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    formContext = context;
                    return SingleChildScrollView(
                      controller: controller,
                      child: FormFieldAnchor(
                        field: 'title',
                        child: const SizedBox(
                          height: 800,
                          child: Text('Title'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              TextButton(
                key: const ValueKey('trigger'),
                onPressed: () {
                  scrollToFirstFormError(
                    formContext,
                    errors: const {},
                    fieldKeys: {
                      'title': FormFieldAnchor.keyFor('title'),
                    },
                  );
                },
                child: const Text('Validate'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('trigger')));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
  });
}
