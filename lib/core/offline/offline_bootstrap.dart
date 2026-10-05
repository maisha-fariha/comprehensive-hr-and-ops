import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../errors/app_error_dialog.dart';
import '../errors/app_snackbar.dart';
import '../network/app_api_client.dart';
import '../network/connectivity_monitor.dart';
import '../network/response_cache.dart';
import '../network/tenant_store.dart';
import '../roles/user_session.dart';
import 'background_sync.dart';
import 'offline_config.dart';
import 'offline_outbox.dart';
import 'offline_overlay.dart';
import 'offline_prewarm.dart';
import 'offline_storage.dart';
import 'outbox_attachments.dart';
import 'outbox_store.dart';
import 'outbox_sync_engine.dart';

/// Wires the encrypted outbox, read cache, connectivity and background sync.
///
/// Every step is defensive: if offline storage cannot start, the app keeps
/// its previous behaviour (legacy queue, no cache) instead of failing launch.
abstract final class OfflineBootstrap {
  static const String _migrationFlag = 'offline_migration_v1';

  static OfflineStorage? _storage;
  static ResponseCache? _cache;

  /// Step 1 (before DI): open encrypted boxes and the read cache.
  static Future<void> openStorage() async {
    try {
      await BackgroundSync.waitForBackgroundWorker();
      BackgroundSync.registerForeground();
      final storage = await OfflineStorage.open();
      if (storage == null) return;
      _storage = storage;
      final cache = ResponseCache(
        values: await storage.openLargeBox(OfflineConfig.cacheBox),
        meta: await storage.openBox('${OfflineConfig.cacheBox}_meta'),
        scope: _cacheScope,
      );
      await cache.ensureReady();
      _cache = cache;
    } catch (error) {
      debugPrint('OfflineBootstrap: storage unavailable ($error)');
    }
  }

  /// Read cache for DI, or null when storage could not start.
  static ResponseCache? get cache => _cache;

  /// Step 2 (after DI): outbox + engine, legacy migration, listeners.
  static Future<void> attach() async {
    final storage = _storage;
    final getIt = GetIt.instance;
    if (storage == null || !getIt.isRegistered<AppApiClient>()) return;
    try {
      final client = getIt<AppApiClient>();
      final store = OutboxStore(await storage.openBox(OfflineConfig.outboxBox));
      final uploads = StagedUploadStore(
        await storage.openBox(OfflineConfig.stagedUploadsBox),
        rootDir: BackgroundSync.outboxDirectory,
      );
      await store.recoverInterrupted();
      unawaited(uploads.purgeOrphans());

      final monitor = Get.isRegistered<ConnectivityMonitor>()
          ? Get.find<ConnectivityMonitor>()
          : null;
      final engine = OutboxSyncEngine(
        store: store,
        uploads: uploads,
        transport: client,
        scope: resolveScope,
        isOnline: () => monitor?.online ?? true,
      );
      final outbox = OfflineOutbox(
        store: store,
        uploads: uploads,
        engine: engine,
        scope: resolveScope,
      );
      client.outbox = outbox;
      Get.put<OfflineOutbox>(outbox, permanent: true);
      AppErrorDialog.inlineOfflineNotices = true;
      OfflineOverlay.currentAuthor = _currentAuthor;
      engine.onSummary = _announce;
      BackgroundSync.attachEngine(engine);

      await _migrateLegacy(outbox);

      if (monitor != null) {
        monitor.hasPendingWork = () => outbox.pendingCount > 0;
        monitor.startPendingPoll();
        ever<bool>(monitor.isOnline, (online) {
          if (online) OfflinePrewarmer.schedule();
        });
      }
      _watchTenant();
      unawaited(BackgroundSync.schedule());
    } catch (error) {
      debugPrint('OfflineBootstrap: outbox unavailable ($error)');
    }
  }

  /// Step 3 (after UserSession is registered): flush + pre-warm on sign-in.
  static void watchSession(UserSession session) {
    ever<String?>(session.userIdListenable, (userId) {
      if (userId == null || userId.isEmpty) return;
      final outbox = OfflineOutbox.maybe;
      if (outbox != null) unawaited(outbox.engine.flush(ignoreBackoff: true));
      OfflinePrewarmer.schedule(delay: const Duration(seconds: 6));
    });
  }

  /// Owner of new outbox items: the signed-in user, or the last profile seen
  /// on this device while a session token is still present (cold start
  /// offline, before `/mobile/me` answers).
  static OutboxScope? resolveScope() {
    final getIt = GetIt.instance;
    final tenant = getIt.isRegistered<TenantStore>()
        ? (getIt<TenantStore>().subdomain ?? '')
        : '';
    String? userId;
    if (Get.isRegistered<UserSession>()) {
      final session = Get.find<UserSession>();
      if (session.isSigningOut) return null;
      userId = session.userId;
    }
    if ((userId == null || userId.isEmpty) &&
        getIt.isRegistered<AuthRepository>()) {
      final auth = getIt<AuthRepository>();
      if (auth.hasSession) userId = auth.lastKnownProfile?.id;
    }
    if (userId == null || userId.isEmpty) return null;
    return OutboxScope(userId: userId, tenant: tenant);
  }

  static Map<String, dynamic>? _currentAuthor() {
    if (!Get.isRegistered<UserSession>()) return null;
    final session = Get.find<UserSession>();
    final id = session.userId;
    if (id == null || id.isEmpty) return null;
    return {
      'id': id,
      'email': session.email,
      'name': session.displayName,
    };
  }

  static String _cacheScope() {
    final getIt = GetIt.instance;
    final tenant = getIt.isRegistered<TenantStore>()
        ? (getIt<TenantStore>().subdomain ?? '')
        : '';
    final userId =
        Get.isRegistered<UserSession>() ? (Get.find<UserSession>().userId ?? '') : '';
    return '$tenant|$userId';
  }

  static void _watchTenant() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<TenantStore>()) return;
    getIt<TenantStore>().onChanged = (previous, next) {
      if (previous != null && previous != next) unawaited(_cache?.clear());
    };
  }

  static void _announce(OutboxSyncSummary summary) {
    if (summary.needsAttention > 0) {
      final n = summary.needsAttention;
      AppSnackbar.show(
        n == 1 ? '1 change needs attention' : '$n changes need attention',
        'Open "Unsent changes" to review.',
      );
      return;
    }
    if (summary.sent > 0) {
      final n = summary.sent;
      AppSnackbar.show(
        n == 1 ? '1 change sent' : '$n changes sent',
        'Your offline changes reached the server.',
      );
    }
  }

  /// One-time move of the legacy unencrypted queue/cache (gems default box).
  static Future<void> _migrateLegacy(OfflineOutbox outbox) async {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<SharedPreferences>() ||
        !getIt.isRegistered<DatabaseService>()) {
      return;
    }
    final prefs = getIt<SharedPreferences>();
    if (prefs.getBool(_migrationFlag) == true) return;
    final db = getIt<DatabaseService>();
    try {
      final raw = db.get<String>(OfflineConfig.legacyQueueKey);
      if (raw != null && raw.isNotEmpty && resolveScope() != null) {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final entry in list) {
            if (entry is! Map) continue;
            final legacy = SyncItem.fromJson(entry.cast<String, dynamic>());
            await outbox.enqueue(
              method: legacy.method,
              path: legacy.endpoint,
              data: legacy.data,
              idempotencyKey: outbox.newIdempotencyKey(),
              occurredAt: legacy.timestamp,
            );
          }
        }
      }
      await db.delete(OfflineConfig.legacyQueueKey);
      await db.clear(boxName: OfflineConfig.legacyCacheBox);
      await prefs.setBool(_migrationFlag, true);
    } catch (error) {
      debugPrint('OfflineBootstrap: legacy migration skipped ($error)');
    }
  }
}
