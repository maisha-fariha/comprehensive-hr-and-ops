import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Plain white header shared by both segments of the "Tasks & Messages"
/// list screen: a back chevron and a centered title.
///
/// Icon note: no matching SVG exists in `assets/icons/*` for a back
/// chevron, so this uses `Icons.arrow_back_ios_new_rounded` as a temporary
/// stand-in, mirroring the same fallback already used by
/// `lib/features/hr/incidents/presentation/widgets/wizard_header.dart`.
class TasksMessagesHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const TasksMessagesHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final iconSlotWidth = ResponsiveHelper.getResponsiveWidth(context, 24);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 10, bottom: 14),
      child: Row(
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
    );
  }
}
