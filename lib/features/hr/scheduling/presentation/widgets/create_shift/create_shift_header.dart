import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';

enum CreateShiftTab {
  shiftInformation,
  staffAssignment,
  openShift,
  recurring,
  notifications,
}

extension CreateShiftTabX on CreateShiftTab {
  String get label => switch (this) {
        CreateShiftTab.shiftInformation => 'Shift Information',
        CreateShiftTab.staffAssignment => 'Staff Assignment',
        CreateShiftTab.openShift => 'Open Shift',
        CreateShiftTab.recurring => 'Recurring',
        CreateShiftTab.notifications => 'Notifications',
      };
}

class CreateShiftHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const CreateShiftHeader({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 18,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  AppAssets.calendarPlus,
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
                      'Add New Shift',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          20,
                        ),
                        color: AppColors.textHeading,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                    ),
                    Text(
                      'Set the timing, assign staff and their tasks, and choose how it repeats.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 22),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          const _RequiredFieldsHint(),
        ],
      ),
    );
  }
}

class _RequiredFieldsHint extends StatelessWidget {
  const _RequiredFieldsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 16),
            color: AppColors.textMuted,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textSecondary,
              ),
              children: const [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: AppColors.criticalRed),
                ),
                TextSpan(text: ' Required fields'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreateShiftStepTabs extends StatelessWidget {
  final CreateShiftTab selected;
  final ValueChanged<CreateShiftTab>? onSelected;

  const CreateShiftStepTabs({
    super.key,
    required this.selected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16),
      child: Row(
        children: [
          for (final tab in CreateShiftTab.values) ...[
            _TabChip(
              tab: tab,
              selected: tab == selected,
              onTap: onSelected == null ? null : () => onSelected!(tab),
            ),
            if (tab != CreateShiftTab.values.last)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final CreateShiftTab tab;
  final bool selected;
  final VoidCallback? onTap;

  const _TabChip({
    required this.tab,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primaryNavy : AppColors.textMuted;
    return Material(
      color: selected ? AppColors.surfaceWhite : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        side: BorderSide(
          color: selected ? AppColors.searchBorder : Colors.transparent,
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
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
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
  final CreateShiftTab tab;
  final Color color;

  const _TabIcon({required this.tab, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case CreateShiftTab.shiftInformation:
        return AppSvgIcon(AppAssets.calendarCheck, size: 16, color: color);
      case CreateShiftTab.staffAssignment:
        return AppSvgIcon(AppAssets.users, size: 16, color: color);
      case CreateShiftTab.openShift:
        return Icon(
          Icons.cell_tower_rounded,
          size: ResponsiveHelper.getResponsiveSize(context, 16),
          color: color,
        );
      case CreateShiftTab.recurring:
        return Icon(
          Icons.sync_rounded,
          size: ResponsiveHelper.getResponsiveSize(context, 16),
          color: color,
        );
      case CreateShiftTab.notifications:
        return AppSvgIcon(AppAssets.bell, size: 16, color: color);
    }
  }
}

class CreateShiftCompletionBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double percent;

  const CreateShiftCompletionBar({
    super.key,
    this.currentStep = 0,
    this.totalSteps = 5,
    this.percent = 0,
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
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
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
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
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
