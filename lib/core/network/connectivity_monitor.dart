import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../config/app_env.dart';
import '../offline/offline_config.dart';
import 'app_api_client.dart';

/// App-wide online/offline flag. Syncs queued writes when connectivity returns.
///
/// "Online" means a network interface is up **and** the API answered a
/// lightweight probe (any HTTP response counts). Two consecutive failed probes
/// are required before going offline, so a single slow request never flips
/// the app into offline mode.
class ConnectivityMonitor extends GetxService with WidgetsBindingObserver {
  final Connectivity _connectivity;
  final Future<bool> Function() _probe;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounce;
  Timer? _offlineProbeTimer;
  Timer? _pendingPoll;
  Future<bool>? _probeInFlight;
  bool _hasInterface = true;
  bool _observing = false;

  final RxBool isOnline = true.obs;

  /// Returns true while the outbox still holds unsent items for this user.
  bool Function()? hasPendingWork;

  ConnectivityMonitor({
    Connectivity? connectivity,
    Future<bool> Function()? probe,
  })  : _connectivity = connectivity ?? Connectivity(),
        _probe = probe ?? _defaultProbe;

  bool get online => isOnline.value;

  Future<ConnectivityMonitor> start() async {
    try {
      _hasInterface = _interfaceUp(await _connectivity.checkConnectivity());
      isOnline.value = _hasInterface;
    } catch (_) {
      _hasInterface = true;
      isOnline.value = true;
    }
    _subscription = _connectivity.onConnectivityChanged.listen(_onInterface);
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    if (_hasInterface) unawaited(_confirmReachability());
    return this;
  }

  /// Re-checks interface + reachability now.
  Future<bool> refresh() async {
    try {
      _hasInterface = _interfaceUp(await _connectivity.checkConnectivity());
    } catch (_) {}
    if (!_hasInterface) {
      _setOnline(false);
      return false;
    }
    return _confirmReachability();
  }

  /// A real API response arrived: the server is reachable.
  void reportReachable() {
    if (!_hasInterface) return;
    _setOnline(true);
  }

  /// A request failed with no response: re-probe soon.
  void reportUnreachable() {
    _debounce?.cancel();
    _debounce = Timer(OfflineConfig.reachabilityDebounce, () {
      unawaited(_confirmReachability());
    });
  }

  /// Polls while the outbox has unsent items, so retries continue without
  /// a connectivity event.
  void startPendingPoll() {
    _pendingPoll ??= Timer.periodic(OfflineConfig.pendingPollInterval, (_) {
      final pending = hasPendingWork?.call() ?? false;
      if (!pending) return;
      unawaited(() async {
        if (await refresh()) await _flushQueue(ignoreBackoff: false);
      }());
    });
  }

  void _onInterface(List<ConnectivityResult> results) {
    _hasInterface = _interfaceUp(results);
    if (!_hasInterface) {
      _debounce?.cancel();
      _setOnline(false);
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(OfflineConfig.reachabilityDebounce, () {
      unawaited(_confirmReachability());
    });
  }

  Future<bool> _confirmReachability() {
    final running = _probeInFlight;
    if (running != null) return running;
    final future = () async {
      if (kIsWeb) {
        _setOnline(_hasInterface);
        return _hasInterface;
      }
      var reachable = await _safeProbe();
      if (!reachable && _hasInterface) {
        await Future<void>.delayed(const Duration(seconds: 2));
        reachable = await _safeProbe();
      }
      _setOnline(reachable && _hasInterface);
      return isOnline.value;
    }();
    _probeInFlight = future;
    return future.whenComplete(() {
      if (identical(_probeInFlight, future)) _probeInFlight = null;
    });
  }

  Future<bool> _safeProbe() async {
    try {
      return await _probe();
    } catch (_) {
      return false;
    }
  }

  void _setOnline(bool next) {
    final wasOffline = !isOnline.value;
    isOnline.value = next;
    if (next) {
      _offlineProbeTimer?.cancel();
      _offlineProbeTimer = null;
      if (wasOffline) unawaited(_flushQueue(ignoreBackoff: true));
    } else if (_hasInterface) {
      // Interface up but API unreachable: keep probing until it answers.
      _offlineProbeTimer ??= Timer.periodic(
        OfflineConfig.offlineProbeInterval,
        (_) => unawaited(_confirmReachability()),
      );
    } else {
      _offlineProbeTimer?.cancel();
      _offlineProbeTimer = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(() async {
      if (await refresh()) await _flushQueue(ignoreBackoff: true);
    }());
  }

  Future<void> _flushQueue({required bool ignoreBackoff}) async {
    try {
      final getIt = GetIt.instance;
      if (getIt.isRegistered<AppApiClient>()) {
        final client = getIt<AppApiClient>();
        final queue = client.outbox;
        if (queue != null) {
          await queue.engine.flush(ignoreBackoff: ignoreBackoff);
        } else {
          await client.flushQueuedWrites();
        }
        return;
      }
      await getIt<SyncService>().syncQueue();
    } catch (_) {}
  }

  static bool _interfaceUp(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  static Dio? _probeClient;

  static Future<bool> _defaultProbe() async {
    final base = _probeBaseUrl();
    if (base.isEmpty) return true;
    final dio = _probeClient ??= Dio(
      BaseOptions(
        connectTimeout: OfflineConfig.reachabilityTimeout,
        receiveTimeout: OfflineConfig.reachabilityTimeout,
        sendTimeout: OfflineConfig.reachabilityTimeout,
        followRedirects: false,
        validateStatus: (_) => true,
      ),
    );
    try {
      final response = await dio.head<void>(base);
      return response.statusCode != null;
    } on DioException catch (error) {
      return error.response != null;
    }
  }

  static String _probeBaseUrl() {
    try {
      if (GetIt.instance.isRegistered<ApiConfig>()) {
        return GetIt.instance<ApiConfig>().baseUrl;
      }
    } catch (_) {}
    return AppEnv.apiBaseUrl;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _debounce?.cancel();
    _offlineProbeTimer?.cancel();
    _pendingPoll?.cancel();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
