import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Header for the "New Message" compose screen: a back chevron, a centered
/// title, and a centered subtitle line beneath it.
///
/// Icon note: no matching SVG exists in `assets/icons/*` for a back
/// chevron, so this uses `Icons.arrow_back_ios_new_rounded` as a temporary
/// stand-in, matching the same fallback already used across the app (e.g.
/// `lib/features/hr/incidents/presentation/widgets/wizard_header.dart`).
class ComposeMessageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const ComposeMessageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final iconSlotWidth = ResponsiveHelper.getResponsiveWidth(context, 24);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 10, bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: iconSlotWidth,
                child: GestureDetector(
                  onTap: onBack ?? Get.back,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 18),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              SizedBox(width: iconSlotWidth),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}
