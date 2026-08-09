import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/missed_dose.dart';
import 'administered_tab_view.dart';
import 'missed_dose_card.dart';

/// Content of the "Missed" tab: "Missed Doses" header + dose list.
class MissedTabView extends StatelessWidget {
  final List<MissedDose> doses;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _pillBg = Color(0xFFFFF0D8);
  static const Color _pillFg = Color(0xFFD97706);

  const MissedTabView({super.key, required this.doses});

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
                'Missed Doses',
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
              text: '${doses.length} flagged',
              background: _pillBg,
              foreground: _pillFg,
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < doses.length; i++) ...[
          MissedDoseCard(dose: doses[i]),
          if (i != doses.length - 1)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        ],
      ],
    );
  }
}
