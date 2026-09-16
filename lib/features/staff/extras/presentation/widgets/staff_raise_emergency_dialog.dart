import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Result of a successful raise — used by callers that need to refresh lists.
class StaffRaiseEmergencyResult {
  final String residenceId;
  final String type;
  final String? locationNote;
  final String? note;

  const StaffRaiseEmergencyResult({
    required this.residenceId,
    required this.type,
    this.locationNote,
    this.note,
  });
}

/// Reference-matched "Raise emergency alarm" modal.
///
/// Dashboard panic icon should call [show] only — no page navigation.
class StaffRaiseEmergencyDialog extends StatefulWidget {
  const StaffRaiseEmergencyDialog({super.key});

  /// Shows the dialog and posts `POST /emergency-alerts` on confirm.
  /// Returns the payload on success, `null` if cancelled / failed.
  static Future<StaffRaiseEmergencyResult?> show() {
    return Get.dialog<StaffRaiseEmergencyResult>(
      const StaffRaiseEmergencyDialog(),
      barrierDismissible: false,
    );
  }

  @override
  State<StaffRaiseEmergencyDialog> createState() =>
      _StaffRaiseEmergencyDialogState();
}

class _StaffRaiseEmergencyDialogState extends State<StaffRaiseEmergencyDialog> {
  static const _emergencyKinds = <({String value, String label})>[
    (value: 'medical', label: 'Medical emergency'),
    (value: 'security', label: 'Security'),
    (value: 'fire', label: 'Fire'),
    (value: 'behavioral', label: 'Behavioral'),
    (value: 'missing', label: 'Missing person'),
    (value: 'other', label: 'Other'),
  ];

  final _locationController = TextEditingController();
  final _noteController = TextEditingController();

  late final AppApiClient _api;
  late final UserSession _session;

  List<({String id, String name})> _homes = const [];
  String? _selectedHomeId;
  String _selectedType = 'medical';
  bool _loadingHomes = true;
  bool _submitting = false;
  String? _homeError;
  String? _typeError;

  @override
  void initState() {
    super.initState();
    _api = GetIt.instance<AppApiClient>();
    _session = Get.find<UserSession>();
    _loadHomes();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadHomes() async {
    final sessionId = _session.residenceId;
    final sessionName = _session.residenceName;
    final result = await _api.get(ApiEndpoints.residences, silent: true);
    if (!mounted) return;

    final homes = <({String id, String name})>[];
    result.when(
      success: (body) {
        for (final item in JsonCodec.unwrapList(body).whereType<Map>()) {
          final json = JsonCodec.asMap(item);
          final id = JsonCodec.string(json['id']);
          if (id == null || id.isEmpty) continue;
          homes.add((
            id: id,
            name: JsonCodec.stringOr(json['name'], 'Residence'),
          ));
        }
      },
      failure: (_) {},
    );

    if (homes.isEmpty && sessionId != null && sessionId.isNotEmpty) {
      homes.add((
        id: sessionId,
        name: (sessionName != null && sessionName.isNotEmpty)
            ? sessionName
            : 'My residence',
      ));
    }

    setState(() {
      _homes = homes;
      _selectedHomeId = homes.any((h) => h.id == sessionId)
          ? sessionId
          : (homes.isNotEmpty ? homes.first.id : null);
      _loadingHomes = false;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _homeError = (_selectedHomeId == null || _selectedHomeId!.isEmpty)
          ? 'Choose a residence'
          : null;
      _typeError = _selectedType.isEmpty ? 'Choose a kind' : null;
    });
    if (_homeError != null || _typeError != null) return;

    setState(() => _submitting = true);
    final location = _locationController.text.trim();
    final note = _noteController.text.trim();
    final result = await _api.post(
      ApiEndpoints.emergencyAlerts,
      data: {
        'residenceId': _selectedHomeId,
        'type': _selectedType,
        'priority': 'standard',
        if (location.isNotEmpty) 'locationNote': location,
        if (note.isNotEmpty) 'note': note,
      },
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    result.when(
      success: (_) {
        Get.back(
          result: StaffRaiseEmergencyResult(
            residenceId: _selectedHomeId!,
            type: _selectedType,
            locationNote: location.isEmpty ? null : location,
            note: note.isEmpty ? null : note,
          ),
        );
        Get.snackbar(
          'Alarm raised',
          'Your team has been notified.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not raise alarm',
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: AppColors.textMuted,
      ),
      filled: true,
      fillColor: AppColors.surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.searchBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.searchBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.secondaryTeal, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.criticalRed),
      ),
    );
  }

  Widget _requiredLabel(String text) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textHeading,
            ),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.criticalRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionalLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.textHeading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveHelper.getResponsiveWidth(context, 420)
        .clamp(280.0, 440.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.criticalRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const AppSvgIcon(
                        'assets/icons/staff_core/panic_siren.svg',
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raise emergency alarm',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                              color: AppColors.textHeading,
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Everyone on the response team is notified immediately.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w400,
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _submitting ? null : () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.dividerLight),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _requiredLabel('Which home'),
                      const SizedBox(height: 8),
                      if (_loadingHomes)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.secondaryTeal,
                              ),
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedHomeId,
                          isExpanded: true,
                          decoration: _fieldDecoration(
                            hint: 'Choose a residence',
                          ).copyWith(errorText: _homeError),
                          hint: const Text(
                            'Choose a residence',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textMuted,
                            ),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.iconChevron,
                          ),
                          items: [
                            for (final home in _homes)
                              DropdownMenuItem(
                                value: home.id,
                                child: Text(
                                  home.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.textHeading,
                                  ),
                                ),
                              ),
                          ],
                          onChanged: _submitting
                              ? null
                              : (value) => setState(() {
                                    _selectedHomeId = value;
                                    _homeError = null;
                                  }),
                        ),
                      const SizedBox(height: 16),
                      _requiredLabel('Kind of emergency'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        isExpanded: true,
                        decoration: _fieldDecoration(
                          hint: 'Choose a kind',
                        ).copyWith(errorText: _typeError),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.iconChevron,
                        ),
                        items: [
                          for (final kind in _emergencyKinds)
                            DropdownMenuItem(
                              value: kind.value,
                              child: Text(
                                kind.label,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.textHeading,
                                ),
                              ),
                            ),
                        ],
                        onChanged: _submitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedType = value;
                                  _typeError = null;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      _optionalLabel('Where in the building'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _locationController,
                        enabled: !_submitting,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textHeading,
                        ),
                        decoration: _fieldDecoration(
                          hint: 'e.g. Room 102, the back stairs',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _optionalLabel('What is happening'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        enabled: !_submitting,
                        maxLines: 4,
                        minLines: 3,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textHeading,
                        ),
                        decoration: _fieldDecoration(
                          hint:
                              'Anything the responder should know before arriving...',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.dividerLight),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _submitting ? null : () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textHeading,
                        side: const BorderSide(color: AppColors.searchBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.criticalRed,
                        disabledBackgroundColor:
                            AppColors.criticalRed.withValues(alpha: 0.55),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Raise alarm',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
