import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/daily_note_overview.dart';
import '../../domain/repositories/staff_daily_logs_repository.dart';

/// GetX controller for the "Daily Note" screen.
///
/// The care-note form fields (Mood / Meals / Sleep / ...) are the same
/// default set for every client per the reference screenshot, so this
/// controller only fetches that list; the tapped client's identity
/// (name/DOB/room) is passed directly into [DailyNotePage] via its
/// constructor rather than routed through this controller, since it comes
/// from whichever Daily Logs row/card the user tapped rather than from a
/// server fetch.
class DailyNoteController extends BaseController<DailyNoteOverview> {
  final StaffDailyLogsRepository repository;

  DailyNoteController({required this.repository}) {
    loadFields();
  }

  DailyNoteOverview? get overview => state.value.data;

  Future<void> loadFields() async {
    setLoading(true);
    final result = await repository.getDailyNoteOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadFields();
}
