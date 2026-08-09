import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/administered_dose.dart';
import 'administered_dose_card.dart';

/// Content of the "Administered" tab: "Administered Today" header + dose list.
class AdministeredTabView extends StatelessWidget {
  final List<AdministeredDose> doses;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _pillBg = Color(0xFFE8F6EF);
  static const Color _pillFg = Color(0xFF2D8A56);

  const AdministeredTabView({super.key, required this.doses});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20),),
        Row(
          children: [
            Expanded(
              child: Text(
                'Administered Today',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: _titleColor,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            StaffMedicationCountLabel(
              text: '${doses.length} done',
              background: _pillBg,
              foreground: _pillFg,
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < doses.length; i++) ...[
          AdministeredDoseCard(dose: doses[i]),
          if (i != doses.length - 1)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        ],
      ],
    );
  }
}

/// Pill label used as a section trailing chip (e.g. "6 done", "1 flagged").
class StaffMedicationCountLabel extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const StaffMedicationCountLabel({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
          color: foreground,
          height: 1,
        ),
      ),
    );
  }
}
