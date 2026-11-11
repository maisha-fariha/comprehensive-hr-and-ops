import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/offline/offline_image.dart';
import '../../../../core/roles/user_session.dart';
import '../../../../core/time/tenant_clock.dart';
import '../../../../core/widgets/app_svg_icon.dart';

/// Web sidebar brand: tenant logo (from Settings → General) + company name.
class HrCompanyBrand extends StatelessWidget {
  /// Optional override; defaults to platform/tenant name.
  final String? name;
  final double maxNameWidth;
  final bool lightOnDark;
  /// When false, only the logo mark is shown (tight headers).
  final bool showName;

  const HrCompanyBrand({
    super.key,
    this.name,
    this.maxNameWidth = 140,
    this.lightOnDark = false,
    this.showName = true,
  });

  static String resolveName({String? override}) {
    final fromArg = override?.trim();
    if (fromArg != null && fromArg.isNotEmpty) return fromArg;
    final platform = TenantClock.platformName?.trim();
    if (platform != null && platform.isNotEmpty) return platform;
    if (Get.isRegistered<UserSession>()) {
      final org = Get.find<UserSession>().organizationName?.trim();
      if (org != null && org.isNotEmpty) return org;
    }
    return 'Organisation';
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserSession>()) {
      return _brand(context, null);
    }
    final session = Get.find<UserSession>();
    // Rebuild when Settings → General branding lands after login sync.
    return Obx(() {
      session.organizationLogoUrl;
      session.organizationName;
      return _brand(context, session);
    });
  }

  Widget _brand(BuildContext context, UserSession? session) {
    final label = resolveName(override: name);
    final logoSize = ResponsiveHelper.getResponsiveSize(context, 28);
    final nameCap =
        ResponsiveHelper.getResponsiveWidth(context, maxNameWidth);
    final fg = lightOnDark ? AppColors.surfaceWhite : AppColors.textHeading;
    final logoFg =
        lightOnDark ? AppColors.surfaceWhite : AppColors.secondaryTeal;
    final sessionLogo = session?.organizationLogoUrl?.trim();
    final logo = (sessionLogo != null && sessionLogo.isNotEmpty)
        ? sessionLogo
        : TenantClock.logoUrl?.trim();
    final hasLogo = logo != null && logo.isNotEmpty;
    final logoBg = hasLogo
        ? AppColors.surfaceWhite
        : (lightOnDark ? AppColors.whiteOpacity13 : AppColors.activeBackground);

    final nameStyle = TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w700,
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
      color: fg,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.hasBoundedWidth;
        final nameChild = Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: nameStyle,
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: logoSize,
              height: logoSize,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: logoBg,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 8),
                ),
              ),
              alignment: Alignment.center,
              child: !hasLogo
                  ? AppSvgIcon(
                      AppAssets.homeSmall,
                      size: 16,
                      color: logoFg,
                    )
                  : Image(
                      image: OfflineImage.provider(logo, withAuth: true),
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, error, stackTrace) => AppSvgIcon(
                        AppAssets.homeSmall,
                        size: 16,
                        color: logoFg,
                      ),
                    ),
            ),
            if (showName) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              if (tight)
                Flexible(child: nameChild)
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: nameCap),
                  child: nameChild,
                ),
            ],
          ],
        );
      },
    );
  }
}
