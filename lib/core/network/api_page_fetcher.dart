import 'package:gems_core/gems_core.dart';

import 'app_api_client.dart';
import 'json_codec.dart';

/// Walks `page=1..n` until the API reports no further pages.
///
/// Use for list screens / overviews that render the **full** result set and
/// have no UI page controls. Screens that already page in the UI
/// (clients, attendance, finance, …) should keep single-page requests.
abstract final class ApiPageFetcher {
  static const int defaultPageSize = 100;
  static const int defaultMaxPages = 50;

  /// Collects every row for [path] with [query] (without `page` / `limit`).
  static Future<Result<List<dynamic>>> fetchAll(
    AppApiClient api, {
    required String path,
    Map<String, dynamic>? query,
    int pageSize = defaultPageSize,
    int maxPages = defaultMaxPages,
    bool silent = false,
  }) async {
    final all = <dynamic>[];
    var totalPages = 1;

    for (var page = 1; page <= maxPages; page++) {
      final result = await api.get(
        path,
        query: {
          ...?query,
          'page': page,
          'limit': pageSize,
        },
        silent: silent,
      );
      if (result.isFailure) {
        return Result.failure(
          result.error ??
              const ApiError(message: 'Could not load the full list.'),
        );
      }

      final rows = JsonCodec.unwrapList(result.value);
      all.addAll(rows);

      final meta = JsonCodec.metaOf(result.value);
      final reported = JsonCodec.integer(meta?['totalPages']);
      if (reported != null && reported > 0) {
        totalPages = reported;
      } else if (rows.length < pageSize) {
        totalPages = page;
      } else {
        // No meta and a full page — keep going until a short page or max.
        totalPages = page + 1;
      }

      if (page >= totalPages || rows.length < pageSize) break;
    }

    return Result.success(all);
  }
}
