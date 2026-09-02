import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/daily_note_client_info.dart';
import '../../domain/entities/daily_note_overview.dart';
import '../../domain/repositories/staff_daily_logs_repository.dart';

/// GetX controller for the "Daily Note" screen.
class DailyNoteController extends BaseController<DailyNoteOverview> {
  final StaffDailyLogsRepository repository;
  final TextEditingController handoverController = TextEditingController();

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

  Future<void> saveNote(
    DailyNoteClientInfo client, {
    required bool submit,
  }) async {
    final body = handoverController.text.trim();
    if (body.isEmpty) {
      Get.snackbar(
        'Note required',
        'Write how the client is doing before saving.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
      );
      return;
    }
    final residenceId =
        client.residenceId ?? Get.find<UserSession>().residenceId ?? '';
    if (client.clientId.isEmpty || residenceId.isEmpty) {
      Get.snackbar(
        'Could not save note',
        'This client is missing an id or residence.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
      );
      return;
    }

    setLoading(true);
    final result = await repository.saveEntry(
      clientId: client.clientId,
      residenceId: residenceId,
      body: body,
      entryId: client.entryId,
      submit: submit,
    );
    if (result.isFailure) {
      setLoading(false);
      Get.snackbar(
        'Could not save note',
        result.error?.message ?? 'Request failed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
      );
      return;
    }

    if (submit && Get.find<UserSession>().canAccessHandovers) {
      await repository.createHandover(
        residenceId: residenceId,
        notes: body,
        clientId: client.clientId,
      );
    }
    setLoading(false);
    Get.snackbar(
      submit ? 'Note submitted' : 'Draft saved',
      submit
          ? 'The care note is now part of the record.'
          : 'Only you can see this draft until you submit.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
    if (submit) Get.back();
  }

  @override
  Future<void> refresh() => loadFields();

  @override
  void onClose() {
    handoverController.dispose();
    super.onClose();
  }
}
