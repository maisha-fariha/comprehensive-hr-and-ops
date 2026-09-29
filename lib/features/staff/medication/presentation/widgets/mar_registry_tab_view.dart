import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/due_dose.dart';
import 'due_dose_card.dart';
import 'administered_tab_view.dart';

/// Web MAR tab — today's scheduled / due occurrences from `GET /mar/round`.
class MarRegistryTabView extends StatelessWidget {
  final List<DueDose> dueNowDoses;
  final List<DueDose> laterTodayDoses;
  final int scheduledCount;
  final ValueChanged<String> onAdminister;
  final ValueChanged<String> onNotGiven;
  final ValueChanged<DueDose>? onOpenClientMedications;
  final bool canWriteScheduled;
  final bool canWritePrn;

  const MarRegistryTabView({
    super.key,
    required this.dueNowDoses,
    required this.laterTodayDoses,
    required this.scheduledCount,
    required this.onAdminister,
    required this.onNotGiven,
    this.onOpenClientMedications,
    this.canWriteScheduled = true,
    this.canWritePrn = false,
  });

  bool _canWrite(DueDose dose) =>
      dose.isPrn ? canWritePrn : canWriteScheduled;

  @override
  Widget build(BuildContext context) {
    final doses = [...dueNowDoses, ...laterTodayDoses];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        Row(
          children: [
            const Expanded(
              child: Text(
                'MAR Administration Registry',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            StaffMedicationCountLabel(
              text: '$scheduledCount scheduled today',
              background: AppColors.scaffoldBackground,
              foreground: AppColors.textMuted,
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (doses.isEmpty)
          const _EmptyRegistry(
            message: 'No doses scheduled for today under these filters.',
          )
        else ...[
          for (var i = 0; i < doses.length; i++) ...[
            DueDoseCard(
              dose: doses[i],
              canWrite: _canWrite(doses[i]),
              onAdminister: () => onAdminister(doses[i].id),
              onNotGiven: () => onNotGiven(doses[i].id),
              onOpenClientMedications: onOpenClientMedications == null
                  ? null
                  : () => onOpenClientMedications!(doses[i]),
            ),
            if (i != doses.length - 1)
              SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
          ],
        ],
      ],
    );
  }
}

class _EmptyRegistry extends StatelessWidget {
  final String message;

  const _EmptyRegistry({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
