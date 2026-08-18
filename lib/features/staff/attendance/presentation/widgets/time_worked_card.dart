import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../staff_core_constants.dart';

/// Nested cool-grey "Time Worked" timer block.
class TimeWorkedCard extends StatelessWidget {
  final String elapsedTimeLabel;

  static const Color _primary = Color(0xFF1A2B3C);
  static const Color _secondary = Color(0xFF6A7C8A);
  static const Color _units = Color(0xFF94A3B8);
  static const Color _surface = Color(0xFFF1F5F9);

  const TimeWorkedCard({super.key, required this.elapsedTimeLabel});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        vertical: 20,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        children: [
          Text(
            'Time Worked',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: _secondary,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(
            elapsedTimeLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                StaffDimens.timerFontSize,
              ),
              color: _primary,
              letterSpacing: 1.4,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.05,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            'HH : MM : SS',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
              color: _units,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
