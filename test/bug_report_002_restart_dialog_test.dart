import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart' hide Response;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comprehensive_hr_and_ops/core/errors/app_error_dialog.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/network/tenant_store.dart';

/// API stand-in. Only GET is used; the rest fall through.
class _Api implements ApiService {
  int statusCode = 401;

  @override
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    return ApiResponse<T>(
      success: false,
      message: 'down',
      statusCode: statusCode,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Api api;
  late AppApiClient client;

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    api = _Api();
    client = AppApiClient(
      api,
      TenantStore(await SharedPreferences.getInstance()),
    );
    AppErrorDialog.releaseTransient();
  });

  tearDown(() {
    AppErrorDialog.releaseTransient();
    Get.reset();
  });

  testWidgets(
      'a phone coming back from power-off does not show Sign-in needed '
      'or Care home is unavailable, and a rejected session still does',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(GetMaterialApp(home: const Scaffold()));
    await tester.pump();

    // Same window main() and resume use, while the radio is still down.
    AppErrorDialog.holdTransient();
    client.tokenRefresher = () async {
      client.refreshFailure = const NetworkError(
        message: 'No connection',
        code: 'offline',
      );
      return false;
    };
    api.statusCode = 401;
    await client.get('/mobile/home');
    await tester.pump();
    expect(find.text('Sign-in needed'), findsNothing);
    expect(find.text('Care home is unavailable'), findsNothing);

    api.statusCode = 500;
    await client.get('/dashboard');
    await tester.pump();
    expect(find.text('Care home is unavailable'), findsNothing);

    // The network answered, so the next server failure is shown.
    AppErrorDialog.releaseTransient();
    final shown = client.get('/dashboard');
    await _pumpSheet(tester);
    expect(find.text('Care home is unavailable'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await _pumpSheet(tester);
    await shown;

    // A refresh the server rejected is still a real sign-in, even in the
    // quiet window.
    AppErrorDialog.holdTransient();
    api.statusCode = 401;
    client.tokenRefresher = () async {
      client.refreshFailure = const AuthError(
        message: 'Refresh rejected',
        code: '401',
      );
      return false;
    };
    final rejected = client.get('/mobile/home');
    await _pumpSheet(tester);
    expect(find.text('Sign-in needed'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await _pumpSheet(tester);
    await rejected;
  });
}

/// The error is a bottom sheet. The first pumps only schedule the route;
/// the slide itself needs a later frame or OK stays below the surface.
Future<void> _pumpSheet(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
