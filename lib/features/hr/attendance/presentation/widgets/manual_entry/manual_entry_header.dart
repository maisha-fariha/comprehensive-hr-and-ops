import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';

enum ManualEntryTab {
  attendanceDetails,
  timeCorrection,
  evidence,
  approval,
}

extension ManualEntryTabX on ManualEntryTab {
  String get label => switch (this) {
        ManualEntryTab.attendanceDetails => 'Details',
        ManualEntryTab.timeCorrection => 'Time Correction',
        ManualEntryTab.evidence => 'Reason & Evidence',
        ManualEntryTab.approval => 'Approval',
      };
}

/// Top header: navy clock badge, title, subtitle, circular close.
class ManualEntryHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const ManualEntryHeader({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 18,
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 44),
            height: ResponsiveHelper.getResponsiveSize(context, 44),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(
              AppAssets.clock,
              size: 22,
              color: Colors.white,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Attendance Entry',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 20),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 4),
                ),
                Text(
                  'Create or correct attendance records manually after reviewing staff clock activity.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _CloseButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 36);
    return Material(
      color: AppColors.surfaceWhite,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.searchBorder),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.close_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 18),
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Peach warning strip under the header.
class ManualEntryWarningBanner extends StatelessWidget {
  const ManualEntryWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.urgentBackground,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 20,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveHelper.getResponsiveHeight(context, 1),
              ),
              child: AppSvgIcon(
                AppAssets.alertTriangle,
                size: 16,
                color: AppColors.urgentAmber,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: Text(
                'Manual entries update attendance records and may affect payroll calculations after approval.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.urgentAmber,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManualEntryStepTabs extends StatelessWidget {
  final ManualEntryTab selected;
  final ValueChanged<ManualEntryTab>? onSelected;

  const ManualEntryStepTabs({
    super.key,
    required this.selected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.filterButtonBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            for (final tab in ManualEntryTab.values) ...[
              _TabChip(
                tab: tab,
                selected: tab == selected,
                onTap: onSelected == null ? null : () => onSelected!(tab),
              ),
              if (tab != ManualEntryTab.values.last)
                SizedBox(
                  width: ResponsiveHelper.getResponsiveWidth(context, 8),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final ManualEntryTab tab;
  final bool selected;
  final VoidCallback? onTap;

  const _TabChip({
    required this.tab,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textMuted;
    return Material(
      color: selected ? AppColors.primaryNavy : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 14,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TabIcon(tab: tab, color: fg),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Text(
                tab.label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  final ManualEntryTab tab;
  final Color color;

  const _TabIcon({required this.tab, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case ManualEntryTab.attendanceDetails:
        return AppSvgIcon(AppAssets.clock, size: 16, color: color);
      case ManualEntryTab.timeCorrection:
        return AppSvgIcon(AppAssets.notePencil, size: 16, color: color);
      case ManualEntryTab.evidence:
        return Icon(
          Icons.description_outlined,
          size: ResponsiveHelper.getResponsiveSize(context, 16),
          color: color,
        );
      case ManualEntryTab.approval:
        return AppSvgIcon(AppAssets.clipboardCheck, size: 16, color: color);
    }
  }
}

class ManualEntryCompletionBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double percent;

  const ManualEntryCompletionBar({
    super.key,
    this.currentStep = 1,
    this.totalSteps = 4,
    this.percent = 25,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 16,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'COMPLETION',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 11),
                  letterSpacing: 0.6,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                'STEP $currentStep OF $totalSteps',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 11),
                  letterSpacing: 0.6,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: ResponsiveHelper.getResponsiveHeight(context, 6),
              backgroundColor: AppColors.dividerLight,
              color: AppColors.secondaryTeal,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            '${percent.round()}% complete',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.secondaryTeal,
            ),
          ),
        ],
      ),
    );
  }
}
