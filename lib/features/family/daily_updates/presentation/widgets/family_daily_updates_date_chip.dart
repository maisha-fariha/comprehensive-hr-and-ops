import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Date row above the Daily Updates timeline, e.g. teal dot + "Today • May 12, 2025".
class FamilyDailyUpdatesDateChip extends StatelessWidget {
  final String label;

  static const Color _todayColor = Color(0xFF1A2B48);
  static const Color _dateColor = Color(0xFF8A97A8);
  static const Color _dotColor = Color(0xFF0E7C7B);

  const FamilyDailyUpdatesDateChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final parts = label.split(RegExp(r'\s*[·•]\s*'));
    final leading = parts.isNotEmpty ? parts.first : label;
    final trailing = parts.length > 1 ? parts.sublist(1).join(' • ') : null;

    return Row(
      children: [
        Container(
          width: ResponsiveHelper.getResponsiveSize(context, 8),
          height: ResponsiveHelper.getResponsiveSize(context, 8),
          decoration: const BoxDecoration(
            color: _dotColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: leading,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: _todayColor,
                    height: 1.2,
                  ),
                ),
                if (trailing != null && trailing.isNotEmpty) ...[
                  TextSpan(
                    text: '  •  ',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: _dateColor,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: trailing,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: _dateColor,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
