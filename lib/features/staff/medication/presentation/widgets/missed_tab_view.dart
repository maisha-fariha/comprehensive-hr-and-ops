import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/missed_dose.dart';
import 'administered_tab_view.dart';
import 'missed_dose_card.dart';

/// Content of the "Missed" tab: the "Missed Doses" section header (with a
/// red "N flagged" trailing pill) followed by the dose list.
class MissedTabView extends StatelessWidget {
  final List<MissedDose> doses;

  const MissedTabView({super.key, required this.doses});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(
          title: 'Missed Doses',
          trailing: StaffMedicationCountLabel(
            text: '${doses.length} flagged',
            background: AppColors.criticalBackground,
            foreground: AppColors.criticalRed,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        for (var i = 0; i < doses.length; i++) ...[
          MissedDoseCard(dose: doses[i]),
          if (i != doses.length - 1) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        ],
      ],
    );
  }
}
