import 'dart:async';

/// Zone-scoped hints for writes made inside [run], so call sites can tag an
/// outbox item, silence dialogs or opt uploads into offline staging without
/// changing repository or [AppApiClient] signatures.
abstract final class OutboxContext {
  static const Symbol _metaKey = #outboxContextMeta;
  static const Symbol _silentKey = #outboxContextSilent;
  static const Symbol _stageKey = #outboxContextStageUploads;

  /// [stageUploads]: an upload (`FormData` POST) made while offline keeps the
  /// file on the device and returns a placeholder URL. Only use where that
  /// URL is sent in a queueable write and is not rendered straight away.
  static Future<T> run<T>(
    Future<T> Function() body, {
    Map<String, String>? meta,
    bool silent = false,
    bool stageUploads = false,
  }) {
    return runZoned(
      body,
      zoneValues: {
        _metaKey: {...OutboxContext.meta, ...?meta},
        _silentKey: silent || OutboxContext.silent,
        _stageKey: stageUploads || OutboxContext.stageUploads,
      },
    );
  }

  static Map<String, String> get meta {
    final value = Zone.current[_metaKey];
    return value is Map<String, String> ? value : const {};
  }

  static bool get silent => Zone.current[_silentKey] == true;

  static bool get stageUploads => Zone.current[_stageKey] == true;
}
