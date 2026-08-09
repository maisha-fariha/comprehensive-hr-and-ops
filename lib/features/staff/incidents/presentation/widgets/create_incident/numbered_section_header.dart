import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Numbered Create Incident section title.
///
/// [filledBadge] true → solid teal square + white numeral (Incident Details).
/// [filledBadge] false → mint square + teal numeral (Severity / People).
class NumberedSectionHeader extends StatelessWidget {
  final int number;
  final String title;
  final bool filledBadge;
  final bool required;

  /// Optional trailing caption (e.g. "OPTIONAL" on Evidence).
  final String? trailingLabel;

  static const Color _teal = Color(0xFF0E7C7B);
  static const Color _mintBadge = Color(0xFFDFF3F1);
  static const Color _asterisk = Color(0xFFE5484D);
  static const Color _trailing = Color(0xFF94A3B8);

  const NumberedSectionHeader({
    super.key,
    required this.number,
    required this.title,
    this.filledBadge = false,
    this.required = false,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = ResponsiveHelper.getResponsiveSize(context, 26);

    return Row(
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            color: _mintBadge,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 8),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: _teal,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: _teal,
                    letterSpacing: 0.6,
                    height: 1.2,
                  ),
                ),
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: _asterisk,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingLabel != null) ...[
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Text(
            trailingLabel!,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
              color: _trailing,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
