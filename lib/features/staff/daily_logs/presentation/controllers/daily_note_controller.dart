import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/daily_note_attachment.dart';
import '../../domain/entities/daily_note_client_info.dart';
import '../../domain/entities/daily_note_field.dart';
import '../../domain/entities/daily_note_overview.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/repositories/staff_daily_logs_repository.dart';
import '../../staff_daily_logs_constants.dart';
import 'staff_daily_logs_controller.dart';

/// GetX controller for the "Daily Note" screen.
class DailyNoteController extends BaseController<DailyNoteOverview> {
  final StaffDailyLogsRepository repository;

  /// Required narrative → `body` on `POST/PATCH /daily-logs/entries`.
  final TextEditingController bodyController = TextEditingController();

  /// Separate handover text → `POST /shift-handovers` only.
  final TextEditingController handoverController = TextEditingController();

  final RxList<DailyNoteAttachment> attachments = <DailyNoteAttachment>[].obs;
  final RxBool flagForAttention = false.obs;
  final RxString selectedShift = ''.obs;

  String? _loadedKey;

  DailyNoteController({required this.repository});

  DailyNoteOverview? get overview => state.value.data;

  /// Loads `GET /daily-logs/entries/{id}` when [client.entryId] is set,
  /// otherwise an empty form for a new note.
  Future<void> ensureLoaded(DailyNoteClientInfo client) async {
    final key = '${client.clientId}:${client.entryId ?? ''}';
    if (_loadedKey == key) return;
    _loadedKey = key;
    await loadForClient(client);
  }

  Future<void> loadForClient(DailyNoteClientInfo client) async {
    setLoading(true);
    final entryId = client.entryId;
    final result = (entryId != null && entryId.isNotEmpty)
        ? await repository.getEntryDetail(entryId)
        : await repository.getEmptyDailyNote();
    result.when(
      success: (note) {
        setSuccess(note);
        bodyController.text = note.body;
        handoverController.clear();
        attachments.assignAll(note.attachments);
        flagForAttention.value = note.flagForAttention;
        selectedShift.value =
            note.shift.isNotEmpty ? note.shift : _shiftForNow();
      },
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  void updateField(DailyNoteFieldKey key, String value) {
    final note = overview;
    if (note == null) return;
    final fields = [
      for (final field in note.fields)
        if (field.key == key) field.copyWith(value: value) else field,
    ];
    final wellnessFilled = fields.any(
      (f) => f.key == DailyNoteFieldKey.wellness && f.value.trim().isNotEmpty,
    );
    setSuccess(
      note.copyWith(
        fields: fields,
        wellnessCheckCompleted: wellnessFilled,
      ),
    );
  }

  void setShift(String shift) {
    selectedShift.value = shift;
    final note = overview;
    if (note == null) return;
    setSuccess(note.copyWith(shift: shift));
  }

  void setFlagForAttention(bool value) {
    flagForAttention.value = value;
    final note = overview;
    if (note == null) return;
    setSuccess(note.copyWith(flagForAttention: value));
  }

  Future<void> pickFieldValue(DailyNoteField field) async {
    final options =
        StaffDailyLogsConstants.noteFieldOptions[field.key.name] ?? const [];
    if (options.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: Get.context!,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in options)
                ListTile(
                  title: Text(option),
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      updateField(field.key, selected);
    }
  }

  Future<void> pickAndUploadAttachment({required bool imagesOnly}) async {
    final picked = await FilePicker.platform.pickFiles(
      type: imagesOnly ? FileType.image : FileType.any,
      allowMultiple: false,
      withData: false,
    );
    final file = picked?.files.single;
    final path = file?.path;
    if (path == null || path.isEmpty) return;

    setLoading(true);
    final upload = await repository.uploadAttachment(
      localPath: path,
      fileName: file!.name,
    );
    setLoading(false);
    if (upload.isFailure) {
      AppErrorDialog.showResultError(
        upload.error,
        fallbackTitle: 'Could not upload file',
      );
      return;
    }
    attachments.add(upload.value!);
  }

  void removeAttachment(DailyNoteAttachment attachment) {
    attachments.remove(attachment);
  }

  Future<void> saveNote(
    DailyNoteClientInfo client, {
    required bool submit,
  }) async {
    final body = bodyController.text.trim();
    if (body.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'Note required',
        message: 'Write how the client is doing before saving.',
      );
      return;
    }
    final residenceId =
        client.residenceId ?? Get.find<UserSession>().residenceId ?? '';
    if (client.clientId.isEmpty || residenceId.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'Could not save note',
        message: 'This client is missing an id or residence.',
      );
      return;
    }

    final note = overview;
    final entryId = client.entryId ?? note?.entryId;

    // Submitted care records cannot be PATCH'd — use amendments.
    if (note?.isSubmitted == true &&
        entryId != null &&
        entryId.isNotEmpty) {
      await _amendSubmitted(entryId: entryId, body: body);
      return;
    }

    // Re-submit of an already submitted note is not allowed via PATCH.
    if (submit && note?.isSubmitted == true) {
      AppErrorDialog.showPageError(
        title: 'Already submitted',
        message:
            'This note is already a care record. Save an amendment instead.',
      );
      return;
    }

    final observations = <String, String>{};
    if (note != null) {
      for (final field in note.fields) {
        final value = field.value.trim();
        if (value.isNotEmpty) {
          observations[field.key.name] = value;
        }
      }
    }

    final wellnessValue = observations['wellness']?.trim() ?? '';
    final wellnessCheckCompleted =
        note?.wellnessCheckCompleted == true || wellnessValue.isNotEmpty;

    setLoading(true);
    final result = await repository.saveEntry(
      clientId: client.clientId,
      residenceId: residenceId,
      body: body,
      entryId: entryId,
      submit: submit,
      observations: observations.isEmpty ? null : observations,
      shift: selectedShift.value.isNotEmpty
          ? selectedShift.value
          : (note?.shift.isNotEmpty == true ? note!.shift : _shiftForNow()),
      wellnessCheckCompleted: wellnessCheckCompleted,
      flagForAttention: flagForAttention.value,
      attachments: attachments.toList(),
    );
    if (result.isFailure) {
      setLoading(false);
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: submit ? 'Could not submit note' : 'Could not save draft',
      );
      return;
    }

    // Handover is a separate resource — only when submitting with text.
    if (submit) {
      final handover = handoverController.text.trim();
      if (handover.isNotEmpty && Get.find<UserSession>().canAccessHandovers) {
        final handoverResult = await repository.createHandover(
          residenceId: residenceId,
          summary: handover,
          clientId: client.clientId,
          flagForAttention: flagForAttention.value,
          submit: true,
        );
        if (handoverResult.isFailure) {
          setLoading(false);
          AppErrorDialog.showResultError(
            handoverResult.error,
            fallbackTitle: 'Note saved, but handover failed',
          );
          _refreshList();
          Get.back();
          return;
        }
      }
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

    _refreshList();

    if (submit) {
      Get.back();
    } else {
      final savedId = result.value;
      if (savedId != null && savedId.isNotEmpty) {
        _loadedKey = '${client.clientId}:$savedId';
        await loadForClient(
          DailyNoteClientInfo(
            initials: client.initials,
            name: client.name,
            dobLabel: client.dobLabel,
            roomLabel: client.roomLabel,
            clientId: client.clientId,
            residenceId: client.residenceId,
            entryId: savedId,
          ),
        );
      }
    }
  }

  Future<void> _amendSubmitted({
    required String entryId,
    required String body,
  }) async {
    final reasonField = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Amend care record'),
        content: TextField(
          controller: reasonField,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Why are you correcting this note?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Amend'),
          ),
        ],
      ),
    );
    final reason = reasonField.text.trim();
    reasonField.dispose();
    if (confirmed != true) return;
    if (reason.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'Reason required',
        message: 'Amendments need a short reason for the audit trail.',
      );
      return;
    }

    setLoading(true);
    final result = await repository.amendEntry(
      entryId: entryId,
      body: body,
      reason: reason,
    );
    setLoading(false);
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not amend note',
      );
      return;
    }

    Get.snackbar(
      'Amendment saved',
      'The original note stays readable; your correction was appended.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
    _refreshList();
    Get.back();
  }

  void _refreshList() {
    try {
      if (Get.isRegistered<StaffDailyLogsController>()) {
        Get.find<StaffDailyLogsController>().refresh();
      } else if (GetIt.instance.isRegistered<StaffDailyLogsController>()) {
        GetIt.instance<StaffDailyLogsController>().refresh();
      }
    } catch (_) {}
  }

  static String _shiftForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'night';
  }

  @override
  Future<void> refresh() async {}

  @override
  void onClose() {
    bodyController.dispose();
    handoverController.dispose();
    super.onClose();
  }
}
