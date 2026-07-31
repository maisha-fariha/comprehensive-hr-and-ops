import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/administered_dose.dart';
import 'administered_dose_card.dart';

/// Content of the "Administered" tab: the "Administered Today" section
/// header (with a "N done" trailing pill) followed by the dose list.
class AdministeredTabView extends StatelessWidget {
  final List<AdministeredDose> doses;

  const AdministeredTabView({super.key, required this.doses});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(
          title: 'Administered Today',
          trailing: StaffMedicationCountLabel(text: '${doses.length} done'),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        for (var i = 0; i < doses.length; i++) ...[
          AdministeredDoseCard(dose: doses[i]),
          if (i != doses.length - 1) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        ],
      ],
    );
  }
}

/// A small pill with a text label (e.g. "6 done", "1 flagged", "1 logged")
/// used as a section header's trailing element on the Administered/Missed/
/// Refused tabs.
class StaffMedicationCountLabel extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const StaffMedicationCountLabel({
    super.key,
    required this.text,
    this.background = AppColors.activeBackground,
    this.foreground = AppColors.activeGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: foreground,
        ),
      ),
    );
  }
}
