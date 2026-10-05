import 'dart:convert';
import 'dart:io';

import 'package:comprehensive_hr_and_ops/core/widgets/change_password_dialog.dart';
import 'package:comprehensive_hr_and_ops/features/auth/data/mappers/auth_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/auth/domain/entities/mobile_profile.dart';
import 'package:comprehensive_hr_and_ops/features/auth/domain/entities/tenant_info.dart';
import 'package:comprehensive_hr_and_ops/features/auth/domain/repositories/auth_repository.dart';
import 'package:comprehensive_hr_and_ops/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.loginResult);

  final Result<MobileProfile> loginResult;

  @override
  Future<Result<TenantInfo>> lookupTenant(String code) async =>
      Result.success(TenantInfo(subdomain: code));

  @override
  Future<Result<MobileProfile>> login({
    required String email,
    required String password,
  }) async =>
      loginResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _openDialog(
  WidgetTester tester,
  ChangePasswordSubmit onSubmit,
) async {
  await tester.pumpWidget(
    GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showChangePasswordDialog(context, onSubmit: onSubmit),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _fill(
  WidgetTester tester, {
  required String current,
  required String next,
  required String confirm,
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), current);
  await tester.enterText(fields.at(1), next);
  await tester.enterText(fields.at(2), confirm);
  await tester.pump();
}

Finder _submitButton() => find.widgetWithText(TextButton, 'Change password');

void main() {
  tearDown(Get.reset);

  group('F01/F02 change password dialog', () {
    testWidgets('every field has a show / hide eye toggle', (tester) async {
      await _openDialog(tester, ({required currentPassword, required newPassword}) async => null);

      expect(find.text('Current password'), findsOneWidget);
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm new password'), findsOneWidget);
      expect(find.byTooltip('Show password'), findsNWidgets(3));

      TextField field(int i) =>
          tester.widget<TextField>(find.byType(TextField).at(i));
      expect(field(0).obscureText, isTrue);

      await tester.tap(find.byTooltip('Show password').first);
      await tester.pump();
      expect(field(0).obscureText, isFalse);
      expect(field(1).obscureText, isTrue);
      expect(find.byTooltip('Hide password'), findsOneWidget);

      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(field(0).obscureText, isTrue);
    });

    testWidgets('submit is disabled until all three fields are filled',
        (tester) async {
      await _openDialog(tester, ({required currentPassword, required newPassword}) async => null);
      expect(tester.widget<TextButton>(_submitButton()).onPressed, isNull);
      await _fill(tester, current: 'old', next: 'newpass12', confirm: '');
      expect(tester.widget<TextButton>(_submitButton()).onPressed, isNull);
      await _fill(tester, current: 'old', next: 'newpass12', confirm: 'newpass12');
      expect(tester.widget<TextButton>(_submitButton()).onPressed, isNotNull);
    });

    testWidgets('uses the web validation copy and never calls the API',
        (tester) async {
      var calls = 0;
      await _openDialog(tester, ({required currentPassword, required newPassword}) async {
        calls++;
        return null;
      });

      await _fill(tester, current: 'old', next: 'short', confirm: 'short');
      await tester.tap(_submitButton());
      await tester.pump();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);

      await _fill(tester, current: 'old', next: 'newpass12', confirm: 'newpass13');
      await tester.tap(_submitButton());
      await tester.pump();
      expect(find.text('The two new passwords do not match.'), findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('server error stays inline and keeps the dialog open',
        (tester) async {
      await _openDialog(tester, ({required currentPassword, required newPassword}) async =>
          'Current password is incorrect');
      await _fill(tester, current: 'wrong', next: 'newpass12', confirm: 'newpass12');
      await tester.tap(_submitButton());
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordDialog), findsOneWidget);
      expect(find.text('Current password is incorrect'), findsOneWidget);
      expect(find.text('Password changed'), findsNothing);
    });

    testWidgets('success closes the dialog and confirms "Password changed"',
        (tester) async {
      String? sentCurrent;
      String? sentNext;
      await _openDialog(tester, ({required currentPassword, required newPassword}) async {
        sentCurrent = currentPassword;
        sentNext = newPassword;
        return null;
      });
      await _fill(tester, current: 'old-pass', next: 'newpass12', confirm: 'newpass12');
      await tester.tap(_submitButton());
      await tester.pumpAndSettle();

      expect(sentCurrent, 'old-pass');
      expect(sentNext, 'newpass12');
      expect(find.byType(ChangePasswordDialog), findsNothing);
      expect(find.text('Password changed'), findsOneWidget);
      expect(
        find.text('Use your new password the next time you sign in.'),
        findsOneWidget,
      );
    });
  });

  group('F03 wrong password at login', () {
    test('401 shows the web copy instead of "Please try again"', () async {
      final controller = AuthController(
        repository: _FakeAuthRepository(
          Result.failure(
            const AuthError(message: 'Invalid credentials', code: '401'),
          ),
        ),
      );
      final ok = await controller.signInWithPassword(
        workspaceCode: 'demo',
        email: 'family@demo.local',
        password: 'wrong-password',
      );
      expect(ok, isFalse);
      expect(controller.errorTitle.value, 'Sign in failed');
      expect(controller.errorMessage.value, 'Email or password is incorrect.');
    });

    test('ApiService keeps the message from the {error:{message}} envelope',
        () async {
      HttpOverrides.global = null;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final body = request.uri.path.endsWith('/login')
            ? {
                'success': false,
                'error': {
                  'code': 'UNAUTHORIZED',
                  'message': 'Invalid credentials',
                },
              }
            : {
                'success': false,
                'error': {
                  'code': 'VALIDATION_ERROR',
                  'message': 'Invalid request',
                  'details': {
                    'formErrors': <String>[],
                    'fieldErrors': {
                      'newPassword': [
                        'String must contain at least 8 character(s)',
                      ],
                    },
                  },
                },
              };
        request.response
          ..statusCode = request.uri.path.endsWith('/login') ? 401 : 400
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(body));
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));

      final api = ApiService(
        ApiConfig(baseUrl: 'http://${server.address.host}:${server.port}'),
      );
      final login = await api.post<dynamic>('/mobile/auth/login', data: {});
      expect(login.success, isFalse);
      expect(login.statusCode, 401);
      expect(login.message, 'Invalid credentials');

      final change = await api.post<dynamic>('/auth/change-password', data: {});
      expect(change.statusCode, 400);
      expect(change.errors, {
        'newPassword': ['String must contain at least 8 character(s)'],
      });
    });
  });

  group('F09 tenant admin is blocked from the mobile app', () {
    Map<String, dynamic> me(List<String> roles, {String realm = 'tenant'}) => {
          'success': true,
          'data': {
            'id': 'u1',
            'email': 'x@demo.local',
            'realm': realm,
            'roles': roles,
            'permissions': <String>[],
          },
        };

    test('tenant_admin and platform realm are web-only', () {
      expect(AuthMapper.isWebOnlyAccount(me(['tenant_admin'])), isTrue);
      expect(AuthMapper.isWebOnlyAccount(me(['Tenant admin'])), isTrue);
      expect(
        AuthMapper.isWebOnlyAccount(me(['manager'], realm: 'platform')),
        isTrue,
      );
    });

    test('manager, staff and family roles still sign in', () {
      for (final role in [
        'family',
        'residence_manager',
        'manager',
        'nurse',
        'caregiver',
        'housekeeper',
      ]) {
        expect(AuthMapper.isWebOnlyAccount(me([role])), isFalse, reason: role);
      }
    });

    test('login page shows "Access restricted" with the restriction copy',
        () async {
      final controller = AuthController(
        repository: _FakeAuthRepository(
          Result.failure(
            const PermissionError(
              message: AuthMapper.restrictedAccountMessage,
              code: 'restricted_role',
            ),
          ),
        ),
      );
      final ok = await controller.signInWithPassword(
        workspaceCode: 'harmony-help',
        email: 'admin@example.com',
        password: 'whatever1',
      );
      expect(ok, isFalse);
      expect(controller.errorTitle.value, 'Access restricted');
      expect(controller.errorMessage.value, AuthMapper.restrictedAccountMessage);
    });
  });
}
