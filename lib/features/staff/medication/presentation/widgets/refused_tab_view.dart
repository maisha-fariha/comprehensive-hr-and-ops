import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/refused_dose.dart';
import 'administered_tab_view.dart';
import 'refused_dose_card.dart';

/// Content of the "Refused" tab: the "Refused by Client" section header
/// (with an amber "N logged" trailing pill) followed by the dose list.
class RefusedTabView extends StatelessWidget {
  final List<RefusedDose> doses;

  const RefusedTabView({super.key, required this.doses});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(
          title: 'Refused by Client',
          trailing: StaffMedicationCountLabel(
            text: '${doses.length} logged',
            background: AppColors.urgentBackground,
            foreground: AppColors.urgentAmber,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        for (var i = 0; i < doses.length; i++) ...[
          RefusedDoseCard(dose: doses[i]),
          if (i != doses.length - 1) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        ],
      ],
    );
  }
}
