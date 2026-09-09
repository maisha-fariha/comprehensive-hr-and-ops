import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/daily_log_summary_stat.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../../domain/entities/daily_logs_overview.dart';
import '../../domain/repositories/daily_logs_repository.dart';

/// GetX controller for the "Daily Logs" screen and its three segmented tabs
/// (Review / Missing / Handover).
class DailyLogsController extends BaseController<DailyLogsOverview> {
  final DailyLogsRepository repository;

  final Rx<DailyLogsTab> selectedTab = DailyLogsTab.review.obs;
  final RxnString acknowledgingHandoverId = RxnString();

  DailyLogsController({required this.repository}) {
    loadOverview();
  }

  DailyLogsOverview? get overview => state.value.data;

  void selectTab(DailyLogsTab tab) => selectedTab.value = tab;

  int _loadGeneration = 0;

  Future<void> loadOverview() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = await repository.getOverview();
    if (generation != _loadGeneration) return;
    result.when(
      success: setSuccess,
      failure: (error) {
        setError(error.message);
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not load Daily Logs',
        );
      },
    );
    setLoading(false);
  }

  Future<void> acknowledgeHandover(String handoverId) async {
    final id = handoverId.trim();
    if (id.isEmpty) return;
    if (acknowledgingHandoverId.value == id) return;

    acknowledgingHandoverId.value = id;
    final result = await repository.acknowledgeHandover(id);
    acknowledgingHandoverId.value = null;

    result.when(
      success: (_) {
        _markHandoverAcknowledgedLocally(id);
        AppSnackbar.show(
          'Handover acknowledged',
          'The handover was marked as acknowledged.',
        );
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not acknowledge handover',
        );
      },
    );
  }

  void _markHandoverAcknowledgedLocally(String handoverId) {
    final current = overview;
    if (current == null) {
      loadOverview();
      return;
    }

    final updatedEntries = current.handoverEntries.map((entry) {
      if (entry.id != handoverId) return entry;
      return entry.copyWith(
        isAcknowledged: true,
        acknowledgementCaption: 'Acknowledged',
      );
    }).toList();

    final pendingAck =
        updatedEntries.where((entry) => !entry.isAcknowledged).length;
    final updatedStats = current.handoverStats.map((stat) {
      if (stat.tag != DailyLogStatTag.pendingAcknowledgement) return stat;
      return DailyLogSummaryStat(
        tag: stat.tag,
        value: '$pendingAck',
        label: stat.label,
        isHighlighted: stat.isHighlighted,
      );
    }).toList();

    setSuccess(
      DailyLogsOverview(
        reviewStats: current.reviewStats,
        submittedLogs: current.submittedLogs,
        submittedLogsTotalCount: current.submittedLogsTotalCount,
        clientStatusSummaries: current.clientStatusSummaries,
        missingStats: current.missingStats,
        missingLogs: current.missingLogs,
        handoverStats: updatedStats,
        handoverEntries: updatedEntries,
      ),
    );
  }

  @override
  Future<void> refresh() => loadOverview();
}
