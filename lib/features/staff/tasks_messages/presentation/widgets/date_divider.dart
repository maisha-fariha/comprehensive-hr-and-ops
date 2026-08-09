import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Centered pill divider shown between groups of messages in the thread,
/// e.g. "Today".
class DateDivider extends StatelessWidget {
  final String label;

  static const Color _background = Color(0xFFE9EEF1);
  static const Color _labelColor = Color(0xFF82909B);

  const DateDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 999)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
            color: _labelColor,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
