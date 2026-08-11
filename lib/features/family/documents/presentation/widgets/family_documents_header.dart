import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// White header for Family Documents: bordered back + centered title.
class FamilyDocumentsHeader extends StatelessWidget {
  final VoidCallback? onBackTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _buttonBorder = Color(0xFFE2E8EE);

  const FamilyDocumentsHeader({super.key, this.onBackTap});

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
          bottom: 0,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBackTap ?? Get.back,
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
                'Documents',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
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
