import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Full-width alert card: warning icon on the left, count + label stacked
/// on the right, with a red top accent border.
class StaffAlertsBanner extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const StaffAlertsBanner({
    super.key,
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final topBar = ResponsiveHelper.getResponsiveHeight(context, 3);
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 40);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowNavy.withValues(alpha: 0.04),
                offset: Offset(
                  0,
                  ResponsiveHelper.getResponsiveHeight(context, 4),
                ),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: topBar,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFD64545),
                      Color(0xFFD64545).withValues(alpha: 0.33),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBEDED),
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 11),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const AppSvgIcon(
                        'assets/icons/staff_core/triangle_alert.svg',
                        size: 18,
                        color: Color(0xFFD64545),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              26,
                            ),
                            color: const Color(0xFFD64545),
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getResponsiveHeight(
                            context,
                            3,
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              12.5,
                            ),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
