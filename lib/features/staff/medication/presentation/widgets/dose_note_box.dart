import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Soft "Reason: …" / "Notes: …" caption box under Missed / Refused cards.
class DoseNoteBox extends StatelessWidget {
  final String label;
  final String text;
  final Color background;

  static const Color _labelColor = Color(0xFF1A2B48);
  static const Color _bodyColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE8EDF2);

  const DoseNoteBox({
    super.key,
    required this.label,
    required this.text,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(color: _borderColor),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: _labelColor,
                height: 1.45,
              ),
            ),
            TextSpan(
              text: text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: _bodyColor,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
