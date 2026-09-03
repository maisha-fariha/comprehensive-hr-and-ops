import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../domain/entities/incident_detail.dart';
import '../../domain/repositories/staff_incidents_repository.dart';

/// GetX controller for the read-only Incident Details screen.
class IncidentDetailsController extends BaseController<IncidentDetail> {
  final StaffIncidentsRepository repository;

  IncidentDetailsController({required this.repository});

  String? _loadedIncidentId;

  Future<void> loadDetail(String incidentId) async {
    if (_loadedIncidentId == incidentId && state.value.data != null) return;
    _loadedIncidentId = incidentId;

    setLoading(true);
    final result = await repository.getIncidentDetail(incidentId);
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<void> acknowledge() async {
    final id = _loadedIncidentId;
    if (id == null) return;
    final result = await repository.acknowledge(id);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not acknowledge',
      );
      return;
    }
    Get.snackbar(
      'Acknowledged',
      'This incident is marked as seen.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
    _loadedIncidentId = null;
    await loadDetail(id);
  }

  Future<void> addNote(String notes) async {
    final id = _loadedIncidentId;
    if (id == null) return;
    final text = notes.trim();
    if (text.isEmpty) return;
    final result = await repository.addInvestigationNote(
      incidentId: id,
      notes: text,
    );
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not add note',
      );
      return;
    }
    _loadedIncidentId = null;
    await loadDetail(id);
  }

  @override
  Future<void> refresh() {
    final incidentId = _loadedIncidentId;
    if (incidentId == null) return Future.value();
    _loadedIncidentId = null;
    return loadDetail(incidentId);
  }
}
