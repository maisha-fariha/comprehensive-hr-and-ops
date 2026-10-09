/// Tunables for the offline outbox, read cache and background sync.
abstract final class OfflineConfig {
  static const String outboxBox = 'hr_outbox_v1';
  static const String stagedUploadsBox = 'hr_staged_uploads_v1';
  static const String cacheBox = 'hr_http_cache_v2';

  /// Legacy storage owned by gems_data_layer's unencrypted default box.
  static const String legacyQueueKey = 'sync_queue';
  static const String legacyCacheBox = 'http_cache';

  static const int maxNetworkAttempts = 8;
  static const Duration backoffBase = Duration(seconds: 5);
  static const Duration backoffCap = Duration(minutes: 15);

  static const int cacheMaxEntries = 2000;
  static const int cacheMaxBytes = 30 * 1024 * 1024;

  static const Duration reachabilityTimeout = Duration(seconds: 5);
  static const Duration reachabilityDebounce = Duration(milliseconds: 800);
  static const Duration pendingPollInterval = Duration(seconds: 60);
  static const Duration offlineProbeInterval = Duration(seconds: 20);

  /// Staged uploads never referenced by a queued write are removed after this.
  static const Duration orphanUploadTtl = Duration(hours: 48);

  static const Duration prewarmThrottle = Duration(minutes: 10);

  /// When true, queued time-sensitive bodies also carry `clientOccurredAt`.
  /// Off until the API confirms it accepts the extra field (strict schemas
  /// reject unknown keys); `X-Client-Occurred-At` is always sent.
  static const bool includeOccurredAtInBody = false;

  static const String idempotencyHeader = 'Idempotency-Key';
  static const String occurredAtHeader = 'X-Client-Occurred-At';

  /// Browsers preflight custom headers; keep web requests unchanged until the
  /// API's CORS `Access-Control-Allow-Headers` lists both headers above.
  static const bool sendClientHeadersOnWeb = false;

  /// Placeholder scheme returned for uploads staged while offline. Replaced
  /// with the real URL when the owning write is replayed.
  static const String stagedUploadScheme = 'offline-upload://';

  static const String backgroundTaskName = 'hr-ops-offline-sync';
  static const String backgroundUniqueName = 'com.comprehensivehr.offline-sync';
}
