import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get_it/get_it.dart';

import 'app_api_client.dart';

/// App-wide online/offline flag. Syncs queued writes when connectivity returns.
class ConnectivityMonitor extends GetxService {
  final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _subscription;

  final RxBool isOnline = true.obs;

  ConnectivityMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  bool get online => isOnline.value;

  Future<ConnectivityMonitor> start() async {
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (_) {
      isOnline.value = true;
    }
    _subscription = _connectivity.onConnectivityChanged.listen(_apply);
    return this;
  }

  Future<bool> refresh() async {
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (_) {}
    return online;
  }

  void _apply(ConnectivityResult result) {
    final next = result != ConnectivityResult.none;
    final wasOffline = !isOnline.value;
    isOnline.value = next;
    if (wasOffline && next) {
      unawaited(_flushQueue());
    }
  }

  Future<void> _flushQueue() async {
    try {
      final getIt = GetIt.instance;
      if (getIt.isRegistered<AppApiClient>()) {
        await getIt<AppApiClient>().flushQueuedWrites();
        return;
      }
      await getIt<SyncService>().syncQueue();
    } catch (_) {}
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
