import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/surface_card.dart';
import '../manager_destinations.dart';

/// "More" tab of the HR bottom navigation — a simple navigation hub for the
/// Manager feature areas that don't have a dedicated bottom-nav slot in the
/// Figma bottom bar (Home/Schedule/Attendance/Alerts/More only has 5 slots).
///
/// This menu itself isn't a distinct Figma frame; it's a pragmatic way to
/// make the Residences, Clients, Daily Logs, Medication, Tasks & Compliance,
/// Team & Reports and Profile & Settings screens reachable end-to-end.
class HrMoreMenuPage extends StatelessWidget {
  const HrMoreMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entries =
        managerDestinations().where((d) => d.inMoreMenu).toList();
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'More',
          style: AppTextStyles.base(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: AppFontWeight.semiBold,
            color: AppColors.textHeading,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: AppDimens.screenPaddingHorizontal,
            vertical: 20,
          ),
          itemCount: entries.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _MoreMenuTile(entry: entry, onTap: entry.open);
          },
        ),
      ),
    );
  }
}

class _MoreMenuTile extends StatelessWidget {
  final ManagerDestination entry;
  final VoidCallback onTap;

  const _MoreMenuTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: AppDimens.cardPaddingHorizontal,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveWidth(context, AppDimens.iconBoxMedium),
              height: ResponsiveHelper.getResponsiveHeight(context, AppDimens.iconBoxMedium),
              decoration: BoxDecoration(
                color: entry.iconBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusIconBoxMedium),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                entry.icon,
                size: ResponsiveHelper.getResponsiveFontSize(context, AppDimens.iconMedium),
                color: entry.iconColor,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.title,
                    style: AppTextStyles.base(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                      fontWeight: AppFontWeight.semiBold,
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    entry.subtitle,
                    style: AppTextStyles.base(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      fontWeight: AppFontWeight.regular,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: ResponsiveHelper.getResponsiveFontSize(context, AppDimens.iconMedium),
              color: AppColors.iconChevron,
            ),
          ],
        ),
      ),
    );
  }
}
