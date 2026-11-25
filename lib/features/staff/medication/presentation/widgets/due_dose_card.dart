import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../hr/medication/presentation/medication_labels.dart';
import '../../domain/entities/due_dose.dart';
import '../../staff_medication_constants.dart';

/// Web MAR Administration Registry row as a stacked mobile card.
class DueDoseCard extends StatelessWidget {
  final DueDose dose;
  final VoidCallback onAdminister;
  final VoidCallback onNotGiven;
  final VoidCallback? onOpenClientMedications;
  final bool canWrite;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDiscontinue;
  final String administeredByName;

  const DueDoseCard({
    super.key,
    required this.dose,
    required this.onAdminister,
    required this.onNotGiven,
    this.onOpenClientMedications,
    this.canWrite = true,
    this.onEdit,
    this.onDelete,
    this.onDiscontinue,
    this.administeredByName = 'you',
  });

  static const Map<String, String> _stateLabels = {
    'given': 'Given',
    'late': 'Given late',
    'due': 'Due now',
    'upcoming': 'Upcoming',
    'overdue': 'Overdue',
    'missed': 'Missed',
    'refused': 'Refused',
    'withheld': 'Withheld',
    'not_available': 'Not available',
  };

  String get _stateLabel => _stateLabels[dose.state] ?? dose.state;

  @override
  Widget build(BuildContext context) {
    final avatar = StaffMedicationConstants.avatarStyle(dose.avatarColor);
    final tone = MedicationLabels.stateTone(dose.state);
    final schedule = dose.isPrn
        ? 'PRN'
        : [
            if (dose.slotLabel.isNotEmpty) dose.slotLabel,
            if (dose.timeLabel.isNotEmpty) dose.timeLabel,
          ].join(' · ');
    final lastAdmin = dose.administeredAt == null
        ? '—'
        : MedicationLabels.time(dose.administeredAt!);

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenClientMedications ?? onAdminister,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: avatar.background,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      dose.residentInitials.isEmpty
                          ? '?'
                          : dose.residentInitials,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: avatar.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dose.residentName.isEmpty
                          ? 'Resident'
                          : dose.residentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  Container(
                    key: ValueKey('staff-mar-state-${dose.id}'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tone.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _stateLabel.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        color: tone.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: avatar.foreground,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dose.medicationName.isEmpty
                          ? 'Medication'
                          : dose.medicationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _metaGrid([
                (
                  'Residence',
                  dose.residenceName.isEmpty ? '—' : dose.residenceName,
                ),
                ('Dosage', dose.dose.isEmpty ? '—' : dose.dose),
                (
                  dose.isPrn ? 'Type' : 'Schedule',
                  schedule.isEmpty ? '—' : schedule,
                ),
                ('Last Admin', lastAdmin),
                if (!dose.isPrn)
                  (
                    'Next Due',
                    dose.timeLabel.isEmpty ? '—' : dose.timeLabel,
                  ),
              ]),
              const SizedBox(height: 6),
              const Divider(height: 1, color: AppColors.cardBorder),
              // Web order: View · Record · Delete · Edit · Discontinue.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Action(
                    key: ValueKey('mar-view-${dose.id}'),
                    icon: Icons.visibility_outlined,
                    label: 'View',
                    onTap: onOpenClientMedications ?? onAdminister,
                  ),
                  if (canWrite)
                    _Action(
                      key: ValueKey('mar-chart-${dose.id}'),
                      icon: Icons.vaccines_outlined,
                      label: 'Record administration',
                      onTap: onAdminister,
                    ),
                  if (canWrite && onDelete != null)
                    _Action(
                      key: ValueKey('mar-delete-${dose.id}'),
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete prescription',
                      danger: true,
                      onTap: onDelete!,
                    ),
                  if (onEdit != null)
                    _Action(
                      key: ValueKey('staff-mar-edit-${dose.id}'),
                      icon: Icons.edit_outlined,
                      label: 'Edit prescription',
                      onTap: onEdit!,
                    ),
                  if (canWrite && onDiscontinue != null)
                    _Action(
                      key: ValueKey('mar-discontinue-${dose.id}'),
                      icon: Icons.block_rounded,
                      label: 'Discontinue',
                      onTap: onDiscontinue!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaGrid(List<(String, String)> cells) {
    return Column(
      children: [
        for (var i = 0; i < cells.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < cells.length ? 8 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _metaCell(cells[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < cells.length
                      ? _metaCell(cells[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _metaCell((String, String) cell) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cell.$1.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 10.5,
            letterSpacing: 0.3,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          cell.$2,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: AppColors.textHeading,
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        icon: Icon(
          icon,
          size: 18,
          color: danger ? AppColors.criticalRed : AppColors.textSecondary,
        ),
      ),
    );
  }
}
