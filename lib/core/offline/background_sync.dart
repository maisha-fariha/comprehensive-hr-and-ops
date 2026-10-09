import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../config/app_env.dart';
import '../network/app_api_client.dart';
import '../network/tenant_store.dart';
import '../network/token_store.dart';
import 'offline_config.dart';
import 'offline_storage.dart';
import 'outbox_attachments.dart';
import 'outbox_store.dart';
import 'outbox_sync_engine.dart';

@pragma('vm:entry-point')
void offlineSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      return await BackgroundSync.runTask();
    } catch (error) {
      debugPrint('BackgroundSync: task failed ($error)');
      return true;
    }
  });
}

/// Best-effort periodic flush while the app is backgrounded or killed.
///
/// Hive boxes must never be open in two isolates at once, so the worker
/// first asks a live foreground isolate to flush; only when none answers does
/// it open the boxes itself. The foreground waits for a running worker to
/// finish before opening its own boxes.
abstract final class BackgroundSync {
  static const String _foregroundPort = 'hr_ops_offline_fg';
  static const String _backgroundPort = 'hr_ops_offline_bg';
  static const String _ping = 'ping';
  static const String _pong = 'pong';

  static ReceivePort? _foreground;
  static OutboxSyncEngine? _engine;

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Foreground: called before opening boxes.
  static Future<void> waitForBackgroundWorker() async {
    if (kIsWeb) return;
    final worker = IsolateNameServer.lookupPortByName(_backgroundPort);
    if (worker == null) return;
    final reply = ReceivePort();
    try {
      worker.send(reply.sendPort);
      await reply.first.timeout(const Duration(seconds: 10));
    } catch (_) {
    } finally {
      reply.close();
    }
  }

  /// Foreground: claim the isolate name so the worker defers to us.
  static void registerForeground() {
    if (kIsWeb) return;
    _foreground?.close();
    final port = ReceivePort();
    _foreground = port;
    IsolateNameServer.removePortNameMapping(_foregroundPort);
    IsolateNameServer.registerPortWithName(port.sendPort, _foregroundPort);
    port.listen((message) async {
      if (message is! List || message.length != 2) return;
      final reply = message[1];
      if (reply is! SendPort) return;
      if (message[0] == _ping) {
        reply.send(_pong);
        try {
          await _engine?.flush();
        } catch (_) {}
        reply.send(true);
      }
    });
  }

  static void attachEngine(OutboxSyncEngine engine) => _engine = engine;

  static Future<void> schedule() async {
    if (!_supported) return;
    try {
      await Workmanager().initialize(offlineSyncCallbackDispatcher);
      await Workmanager().registerPeriodicTask(
        OfflineConfig.backgroundUniqueName,
        OfflineConfig.backgroundTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (error) {
      debugPrint('BackgroundSync: could not schedule ($error)');
    }
  }

  /// Worker entry point. Always resolves true so the OS keeps the schedule.
  static Future<bool> runTask() async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (await _delegateToForeground()) return true;

    final waiters = <SendPort>[];
    final control = ReceivePort();
    IsolateNameServer.removePortNameMapping(_backgroundPort);
    IsolateNameServer.registerPortWithName(control.sendPort, _backgroundPort);
    OutboxSyncEngine? engine;
    control.listen((message) {
      if (message is SendPort) {
        waiters.add(message);
        engine?.requestYield();
      }
    });

    OutboxStore? store;
    StagedUploadStore? uploads;
    try {
      final storage = await OfflineStorage.open(requireKey: true);
      if (storage == null) return true;

      final prefs = await SharedPreferences.getInstance();
      final api = ApiService(const ApiConfig(baseUrl: AppEnv.apiBaseUrl));
      final tokens = TokenStore(prefs, api)..applyToClient();
      if (!tokens.hasAccessToken) return true;
      final tenant = TenantStore(prefs);
      await tenant.load();

      final client = AppApiClient(api, tenant);
      final auth = AuthRepositoryImpl(api: client, tokens: tokens, tenant: tenant);
      client.tokenRefresher = () async =>
          (await auth.refreshTokens(silent: true)).isSuccess;

      final userId = auth.lastKnownProfile?.id ?? '';
      if (userId.isEmpty) return true;
      final owner = OutboxScope(userId: userId, tenant: tenant.subdomain ?? '');

      store = OutboxStore(await storage.openBox(OfflineConfig.outboxBox));
      uploads = StagedUploadStore(
        await storage.openBox(OfflineConfig.stagedUploadsBox),
        rootDir: outboxDirectory,
      );
      await store.recoverInterrupted();
      engine = OutboxSyncEngine(
        store: store,
        uploads: uploads,
        transport: client,
        scope: () => owner,
        isOnline: () => true,
      );
      await engine.flush();
      engine.dispose();
    } finally {
      await store?.close();
      await uploads?.close();
      IsolateNameServer.removePortNameMapping(_backgroundPort);
      control.close();
      for (final waiter in waiters) {
        waiter.send(true);
      }
    }
    return true;
  }

  /// True when a live foreground isolate took over the flush.
  static Future<bool> _delegateToForeground() async {
    final foreground = IsolateNameServer.lookupPortByName(_foregroundPort);
    if (foreground == null) return false;
    final reply = ReceivePort();
    final events = StreamIterator(reply);
    try {
      foreground.send([_ping, reply.sendPort]);
      final alive = await events
          .moveNext()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (!alive || events.current != _pong) {
        IsolateNameServer.removePortNameMapping(_foregroundPort);
        return false;
      }
      await events
          .moveNext()
          .timeout(const Duration(seconds: 25), onTimeout: () => false);
      return true;
    } catch (_) {
      return true;
    } finally {
      await events.cancel();
      reply.close();
    }
  }

  static Future<Directory> outboxDirectory() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/outbox');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
