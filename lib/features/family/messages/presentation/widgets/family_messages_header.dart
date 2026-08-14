import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// White header for the Family "Messages" list: bordered back + centered title.
class FamilyMessagesHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _buttonBorder = Color(0xFFE2E8EE);

  const FamilyMessagesHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          top: 10,
          bottom: 12,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack ?? Get.back,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _buttonBorder),
                  borderRadius: BorderRadius.circular(radius),
                ),
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: 3.14159,
                  child: const AppSvgIcon(
                    AppAssets.chevronRight,
                    size: 18,
                    color: _titleColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  color: _titleColor,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(width: buttonSize),
          ],
        ),
      ),
    );
  }
}
