import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/emergency_alert.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../emergency_labels.dart';

typedef EmergencyLocator = Future<({double latitude, double longitude})?> Function();

/// Best-effort position, given up after 3 seconds like the web.
Future<({double latitude, double longitude})?> emergencyDeviceLocation() async {
  try {
    return await _devicePosition().timeout(const Duration(seconds: 3));
  } catch (_) {
    return null;
  }
}

Future<({double latitude, double longitude})?> _devicePosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
  return (latitude: position.latitude, longitude: position.longitude);
}

/// Opens "Raise emergency alarm". Resolves to true once an alarm was raised.
Future<bool?> showRaiseEmergencySheet(
  BuildContext context, {
  required EmergencyRepository repository,
  EmergencyLocator locate = emergencyDeviceLocation,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RaiseEmergencySheet(repository: repository, locate: locate),
  );
}

class RaiseEmergencySheet extends StatefulWidget {
  final EmergencyRepository repository;
  final EmergencyLocator locate;

  const RaiseEmergencySheet({
    super.key,
    required this.repository,
    required this.locate,
  });

  @override
  State<RaiseEmergencySheet> createState() => _RaiseEmergencySheetState();
}

class _RaiseEmergencySheetState extends State<RaiseEmergencySheet> {
  final _where = TextEditingController();
  final _what = TextEditingController();
  List<EmergencyOption> _residences = const [];
  String? _residenceId;
  String _type = 'medical';
  String? _error;
  bool _raising = false;

  @override
  void initState() {
    super.initState();
    _loadResidences();
  }

  @override
  void dispose() {
    _where.dispose();
    _what.dispose();
    super.dispose();
  }

  Future<void> _loadResidences() async {
    final result = await widget.repository.residences();
    if (!mounted) return;
    result.when(
      success: (list) => setState(() => _residences = list),
      failure: (_) {},
    );
  }

  /// A single home is chosen for you.
  String? get _effectiveResidence =>
      _residenceId ?? (_residences.length == 1 ? _residences.first.id : null);

  Future<void> _raise() async {
    setState(() => _error = null);
    final residenceId = _effectiveResidence;
    if (residenceId == null) {
      setState(() => _error = 'Choose where help is needed.');
      return;
    }
    setState(() => _raising = true);
    final position = await widget.locate();
    final result = await widget.repository.raise(
      residenceId: residenceId,
      type: _type,
      note: _what.text.trim().isEmpty ? null : _what.text.trim(),
      locationNote: _where.text.trim().isEmpty ? null : _where.text.trim(),
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
    if (!mounted) return;
    setState(() => _raising = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Alarm raised — the response team has been alerted', '');
        Navigator.of(context).pop(true);
      },
      failure: (e) => setState(() => _error = e.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final residenceLabel = _residences
        .where((r) => r.id == _effectiveResidence)
        .map((r) => r.label)
        .firstOrNull;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.criticalRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.crisis_alert_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raise emergency alarm',
                            style: handoverText(context, 16, weight: FontWeight.w600),
                          ),
                          Text(
                            'Everyone on the response team is notified immediately.',
                            style: handoverText(context, 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Container(
                    key: const ValueKey('raise-emergency-error'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.criticalBackgroundSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: handoverText(context, 13.5, color: AppColors.criticalRed),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                HandoverSelect(
                  key: const ValueKey('raise-emergency-residence'),
                  label: 'Which home',
                  required: true,
                  value: residenceLabel,
                  placeholder: 'Choose a residence',
                  onTap: () async {
                    final picked = await pickHandoverOption(
                      context,
                      title: 'Which home',
                      options: [for (final r in _residences) (r.id, r.label)],
                      selected: _effectiveResidence,
                    );
                    if (picked != null) setState(() => _residenceId = picked);
                  },
                ),
                const SizedBox(height: 14),
                HandoverSelect(
                  key: const ValueKey('raise-emergency-type'),
                  label: 'Kind of emergency',
                  required: true,
                  value: EmergencyLabels.type(_type),
                  placeholder: 'Medical emergency',
                  onTap: () async {
                    final picked = await pickHandoverOption(
                      context,
                      title: 'Kind of emergency',
                      options: EmergencyLabels.types,
                      selected: _type,
                    );
                    if (picked != null) setState(() => _type = picked);
                  },
                ),
                const SizedBox(height: 14),
                HandoverTextArea(
                  key: const ValueKey('raise-emergency-where'),
                  label: 'Where in the building',
                  controller: _where,
                  placeholder: 'e.g. Room 102, the back stairs',
                  minLines: 1,
                ),
                const SizedBox(height: 14),
                HandoverTextArea(
                  key: const ValueKey('raise-emergency-what'),
                  label: 'What is happening',
                  controller: _what,
                  placeholder: 'Anything the responder should know before arriving…',
                  minLines: 3,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HandoverButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.criticalRed,
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                        key: const ValueKey('raise-emergency-submit'),
                        borderRadius: BorderRadius.circular(9),
                        onTap: _raising ? null : _raise,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            _raising ? 'Raising…' : 'Raise alarm',
                            style: handoverText(
                              context,
                              13.5,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The red "Emergency" pill from the web header.
class EmergencyRaiseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool onDark;

  const EmergencyRaiseButton({
    super.key,
    required this.onPressed,
    this.onDark = false,
  });

  /// The web hides the label below its `sm` breakpoint.
  static const double _labelBreakpoint = 640;

  @override
  Widget build(BuildContext context) {
    final showLabel = MediaQuery.sizeOf(context).width >= _labelBreakpoint;
    return Semantics(
      label: 'Raise emergency alarm',
      button: true,
      excludeSemantics: true,
      child: Material(
        color: AppColors.criticalRed,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          key: const ValueKey('raise-emergency-button'),
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Container(
            height: 32,
            constraints: const BoxConstraints(minWidth: 32),
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 9),
            decoration: onDark
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.crisis_alert_rounded, size: 14, color: Colors.white),
                if (showLabel) ...[
                  const SizedBox(width: 6),
                  Text(
                    'Emergency',
                    style: handoverText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
