import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/widgets/app_svg_icon.dart';

/// Red-tinted alert box shown inside the Incident Summary card when the
/// incident's severity is High or Critical.
class HighSeverityAlertBanner extends StatelessWidget {
  static const Color _background = Color(0xFFFEF2F2);
  static const Color _border = Color(0xFFFECACA);
  static const Color _foreground = Color(0xFF991B1B);

  const HighSeverityAlertBanner({super.key});

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
        color: _background,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: ResponsiveHelper.getResponsiveHeight(context, 1),
            ),
            child: AppSvgIcon(
              'assets/icons/staff_incidents/alert.svg',
              size: ResponsiveHelper.getResponsiveSize(context, 16),
              color: _foreground,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Text(
              'High-severity incident — supervisor review required within 24 hours.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: _foreground,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
