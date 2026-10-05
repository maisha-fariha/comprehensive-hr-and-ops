import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_appointment.dart';
import '../controllers/hr_appointments_controller.dart';
import '../hr_appointments_labels.dart';

/// "Recent Daily Log Context": up to four of today's current care notes for
/// the resident.
class HrAppointmentDayLogPanel extends StatefulWidget {
  final HrAppointmentsController controller;
  final String clientId;
  final String residenceId;
  final String? clientName;

  const HrAppointmentDayLogPanel({
    super.key,
    required this.controller,
    required this.clientId,
    required this.residenceId,
    this.clientName,
  });

  @override
  State<HrAppointmentDayLogPanel> createState() => _HrAppointmentDayLogPanelState();
}

class _HrAppointmentDayLogPanelState extends State<HrAppointmentDayLogPanel> {
  List<HrAppointmentLogNote> _notes = const [];
  bool _loading = false;
  int _serial = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HrAppointmentDayLogPanel old) {
    super.didUpdateWidget(old);
    if (old.clientId != widget.clientId || old.residenceId != widget.residenceId) _load();
  }

  Future<void> _load() async {
    final serial = ++_serial;
    final pending = widget.controller.dayLog(widget.clientId, widget.residenceId);
    setState(() {
      _notes = const [];
      _loading = true;
    });
    final result = await pending;
    if (!mounted || serial != _serial) return;
    setState(() {
      _loading = false;
      _notes = result?.when(
            success: (notes) => notes.where((n) => !n.isSuperseded).take(4).toList(),
            failure: (_) => const <HrAppointmentLogNote>[],
          ) ??
          const [];
    });
  }

  static (IconData, HrAppointmentTone) _tagStyle(String tag) => switch (tag) {
        'Medication' => (Icons.medication_outlined, HrAppointmentTone.secondary),
        'Activity' => (Icons.auto_awesome_outlined, HrAppointmentTone.success),
        'Behavior' => (Icons.warning_amber_rounded, HrAppointmentTone.warning),
        _ => (Icons.info_outline_rounded, HrAppointmentTone.neutral),
      };

  @override
  Widget build(BuildContext context) {
    final hasClient = widget.clientId.isNotEmpty;
    return Column(
      key: const ValueKey('appointment-day-log'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recent Daily Log Context',
          style: handoverText(context, 13.5, weight: FontWeight.w700, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 2),
        Text(
          hasClient
              ? "Today's care notes for ${widget.clientName ?? 'this resident'}"
              : "Select a resident to see today's care notes",
          style: handoverText(context, 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        if (_notes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              !hasClient
                  ? 'No resident selected yet.'
                  : _loading
                      ? "Loading today's log…"
                      : "Nothing written in today's log yet.",
              textAlign: TextAlign.center,
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          )
        else
          for (final note in _notes)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final (icon, tone) = _tagStyle(note.tag);
                      return Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: tone.background,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon, size: 14, color: tone.foreground),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: note.title,
                            children: [
                              TextSpan(
                                text: '  ${WebFormat.time(note.at)}',
                                style: handoverText(context, 12.5, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          style: handoverText(context, 12.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
                        ),
                        const SizedBox(height: 2),
                        Text(note.body, style: handoverText(context, 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
