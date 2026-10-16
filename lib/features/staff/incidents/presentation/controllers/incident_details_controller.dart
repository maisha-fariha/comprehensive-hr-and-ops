import 'dart:typed_data';

import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../../../hr/incidents/data/cir_pdf_builder.dart';
import '../../domain/entities/incident_detail.dart';
import '../../domain/entities/incident_evidence_item.dart';
import '../../domain/repositories/staff_incidents_repository.dart';

/// GetX controller for the read-only Incident Details screen.
class IncidentDetailsController extends BaseController<IncidentDetail> {
  final StaffIncidentsRepository repository;

  IncidentDetailsController({required this.repository});

  String? _loadedIncidentId;
  final RxBool isOpeningCirPdf = false.obs;
  final RxBool isOpeningEvidence = false.obs;

  Future<void> loadDetail(String incidentId, {bool force = false}) async {
    if (!force &&
        _loadedIncidentId == incidentId &&
        state.value.data != null) {
      return;
    }
    _loadedIncidentId = incidentId;

    final showSpinner = state.value.data == null;
    if (showSpinner) setLoading(true);
    final result = await repository.getIncidentDetail(incidentId);
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    if (showSpinner) setLoading(false);
  }

  Future<void> acknowledge() async {
    final id = _loadedIncidentId;
    if (id == null) return;
    final result = await repository.acknowledge(id);
    if (result.isFailure) {
      await Future<void>.delayed(Duration.zero);
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not acknowledge',
      );
      return;
    }
    await Future<void>.delayed(Duration.zero);
    AppSnackbar.show('Acknowledged', 'This incident is marked as seen.');
    await loadDetail(id, force: true);
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
      await Future<void>.delayed(Duration.zero);
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not add note',
      );
      return;
    }
    await Future<void>.delayed(Duration.zero);
    AppSnackbar.show('Note added', 'Investigation note was saved.');
    await loadDetail(id, force: true);
  }

  /// Share CIR PDF built with the same [CirPdfBuilder] as manager details.
  Future<void> shareCirPdf() async {
    await _handleCirPdf(forPrint: false);
  }

  /// Print CIR PDF via [Printing.layoutPdf].
  Future<void> printCirPdf() async {
    await _handleCirPdf(forPrint: true);
  }

  Future<void> _handleCirPdf({required bool forPrint}) async {
    final detail = state.value.data;
    final summary = detail?.cirReport;
    if (summary == null || isOpeningCirPdf.value) return;
    isOpeningCirPdf.value = true;

    final shortId =
        summary.id.length > 8 ? summary.id.substring(0, 8) : summary.id;
    final fileName = 'CIR-$shortId.pdf';
    final generatedFor = Get.isRegistered<UserSession>()
        ? Get.find<UserSession>().displayName
        : '';

    try {
      final pdfBytes = await CirPdfBuilder.build(
        summary: summary,
        generatedForName:
            generatedFor.trim().isEmpty ? 'User' : generatedFor.trim(),
      );

      if (forPrint) {
        await Printing.layoutPdf(
          name: fileName,
          onLayout: (_) async => pdfBytes,
        );
      } else {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fileName,
          subject: summary.title,
          body: 'Critical Incident Report — ${summary.title}',
        );
      }
    } catch (error) {
      AppSnackbar.show(
        forPrint ? 'Could not print PDF' : 'Could not share PDF',
        error.toString(),
      );
    } finally {
      isOpeningCirPdf.value = false;
    }
  }

  Future<void> openEvidence(IncidentEvidenceItem item) async {
    if (isOpeningEvidence.value) return;
    final url = item.fileUrl.trim();
    if (url.isEmpty) {
      AppSnackbar.show('Unavailable', 'This file has no download link.');
      return;
    }

    isOpeningEvidence.value = true;
    try {
      final result = await repository.downloadFileBytes(url);
      if (result.isFailure) {
        AppErrorDialog.showResultError(
          result.error,
          fallbackTitle: 'Could not download file',
        );
        return;
      }

      final fileBytes = result.value;
      if (fileBytes == null || fileBytes.isEmpty) {
        AppSnackbar.show('Could not download file', 'File content was empty.');
        return;
      }

      final bytes = Uint8List.fromList(fileBytes);
      final fileName = _downloadFileName(item);
      final isPdf = item.extensionLabel == 'PDF' ||
          item.fileType.toLowerCase().contains('pdf');

      if (isPdf) {
        final saveResult = await MediaStoreDownload.savePdfAndOpen(
          fileName: fileName.toLowerCase().endsWith('.pdf')
              ? fileName
              : '$fileName.pdf',
          bytes: bytes,
        );
        if (!saveResult.success) {
          AppSnackbar.show(
            'Could not open file',
            saveResult.error ?? 'Could not save or open the file.',
            force: true,
          );
          return;
        }
        _confirmDownloaded(saveResult.displayLocation);
        return;
      }

      final mime = _mimeFor(item);
      final saveResult = await MediaStoreDownload.saveFileAndOpen(
        fileName: fileName,
        bytes: bytes,
        mimeType: mime,
        chooserTitle: 'Open evidence',
      );
      if (!saveResult.success) {
        AppSnackbar.show(
          'Could not open file',
          saveResult.error ?? 'Could not save or open the file.',
          force: true,
        );
        return;
      }
      _confirmDownloaded(saveResult.displayLocation);
    } finally {
      isOpeningEvidence.value = false;
    }
  }

  /// Shown only after the file is saved. A failed download keeps its error toast.
  void _confirmDownloaded(String location) {
    final where = location.trim();
    AppSnackbar.show(
      'Document downloaded successfully.',
      where.isEmpty ? '' : 'Saved to $where.',
      force: true,
    );
  }

  /// `fileName` is often the mime type (`image/jpeg`) when the upload stored
  /// no real name. A slash makes the phone look for `Download/image/jpeg`.
  static String _downloadFileName(IncidentEvidenceItem item) {
    final raw = item.fileName.trim();
    final urlName = Uri.tryParse(item.fileUrl)
            ?.pathSegments
            .where((part) => part.isNotEmpty)
            .lastOrNull ??
        '';
    final rawIsFile = raw.isNotEmpty &&
        !raw.contains('/') &&
        !raw.contains('\\') &&
        raw.contains('.');
    if (rawIsFile) {
      return raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    }
    if (urlName.contains('.') && !urlName.contains('/')) {
      return urlName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    }
    final ext = switch (item.extensionLabel) {
      'PDF' => 'pdf',
      'PNG' => 'png',
      'JPG' || 'JPEG' => 'jpg',
      'WEBP' => 'webp',
      'GIF' => 'gif',
      _ => 'bin',
    };
    return 'evidence.$ext';
  }

  static String _mimeFor(IncidentEvidenceItem item) {
    final type = item.fileType.toLowerCase();
    if (type.contains('/')) return type;
    switch (item.extensionLabel) {
      case 'PDF':
        return 'application/pdf';
      case 'PNG':
        return 'image/png';
      case 'JPG':
      case 'JPEG':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Future<void> refresh() {
    final incidentId = _loadedIncidentId;
    if (incidentId == null) return Future.value();
    return loadDetail(incidentId, force: true);
  }
}