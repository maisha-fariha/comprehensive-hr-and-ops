import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';

/// Soft mint info banner at the bottom of Daily Updates.
class FamilyDailyUpdatesFooterBanner extends StatelessWidget {
  final String message;

  static const Color _bg = Color(0xFFEAF6F0);
  static const Color _fg = Color(0xFF2E8C58);
  static const String _shieldCheck = 'assets/icons/family_core/shield_check.svg';

  const FamilyDailyUpdatesFooterBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 28),
            height: ResponsiveHelper.getResponsiveSize(context, 28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(_shieldCheck, size: 14,),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: _fg,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
