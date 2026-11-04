import 'package:comprehensive_hr_and_ops/features/hr/org_settings/presentation/pages/org_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings:read only keeps General read-only (Residence Manager)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrgSettingsPage(
          showShell: false,
          load: () async => const OrgSettingsSnapshot(
            canWrite: false,
            settings: {
              'general': {
                'timezone': 'Asia/Dhaka',
                'dateFormat': 'DD/MM/YYYY',
                'timeFormat': '12h',
                'itemsPerPage': 20,
              },
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Asia/Dhaka'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNothing);
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save changes'),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('settings tabs open and scroll on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrgSettingsPage(
          showShell: false,
          load: () async => const OrgSettingsSnapshot(
            canWrite: true,
            defaultBreakMinutes: 30,
            settings: {
              'general': {
                'timezone': 'America/Vancouver',
                'dateFormat': 'DD/MM/YYYY',
                'timeFormat': '12h',
                'itemsPerPage': 20,
              },
              'notifications': {
                'quietHours': {
                  'enabled': false,
                  'start': '21:00',
                  'end': '07:00',
                },
                'digest': {'enabled': false, 'sendAt': '08:00'},
                'alwaysImmediateFrom': 'high',
                'detailedPushPreview': false,
                'escalateAfterMinutes': 0,
                'retentionDays': 0,
              },
              'family_portal_visibility': {
                'activities': true,
                'incidents': true,
                'medications': true,
                'medicalConditions': true,
                'documents': true,
                'appointments': true,
                'messages': true,
              },
              'payroll': {
                'payPeriodType': 'bi_weekly',
                'overtimeEnabled': false,
                'staffSelfServiceEnabled': false,
              },
              'compliance_scoring': {
                'weights': {
                  'expiredDocuments': 5,
                  'openIncidents': 5,
                  'incompleteTraining': 2,
                  'medicationRefillNeeded': 3,
                },
              },
              'inventory_client_tagging': {'mode': 'client_and_remark'},
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.textContaining('America/Vancouver'), findsOneWidget);
    expect(find.text('31/12/2026'), findsOneWidget);
    expect(find.text('12-hour'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);

    await tester.ensureVisible(find.text('Care & operations'));
    await tester.tap(find.text('Care & operations'));
    await tester.pumpAndSettle();
    expect(find.text('COMPLIANCE SCORE'), findsOneWidget);
    expect(find.text('Name the resident, or write a remark'), findsOneWidget);
    expect(find.text('30'), findsWidgets);

    final save = find.text('Save changes');
    expect(tester.getRect(save).top, greaterThan(640));
    await tester.scrollUntilVisible(
      save,
      400,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('org-settings-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(save).bottom, lessThan(640));
    expect(tester.takeException(), isNull);
  });
}
