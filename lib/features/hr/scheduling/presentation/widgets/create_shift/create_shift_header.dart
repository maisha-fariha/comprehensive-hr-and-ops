import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../domain/entities/create_shift_draft.dart';

extension CreateShiftStepX on CreateShiftStep {
  String get label => switch (this) {
        CreateShiftStep.shiftInformation => 'Shift Information',
        CreateShiftStep.staffAssignment => 'Staff Assignment',
        CreateShiftStep.openShift => 'Open Shift',
        CreateShiftStep.recurring => 'Recurring',
        CreateShiftStep.notifications => 'Notifications',
      };

  String get description => switch (this) {
        CreateShiftStep.shiftInformation => 'Timing & residence',
        CreateShiftStep.staffAssignment => 'Assign or leave open',
        CreateShiftStep.openShift => 'Bidding & eligibility',
        CreateShiftStep.recurring => 'Repeat pattern',
        CreateShiftStep.notifications => 'Alerts & reminders',
      };
}

class CreateShiftHeader extends StatelessWidget {
  final VoidCallback? onClose;
  final String title;

  const CreateShiftHeader({
    super.key,
    this.onClose,
    this.title = 'Add New Shift',
  });

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
                      title,
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

class CreateShiftStepTabs extends StatefulWidget {
  final CreateShiftStep selected;
  final Set<CreateShiftStep> completed;
  final ValueChanged<CreateShiftStep>? onSelected;

  const CreateShiftStepTabs({
    super.key,
    required this.selected,
    this.completed = const {},
    this.onSelected,
  });

  @override
  State<CreateShiftStepTabs> createState() => _CreateShiftStepTabsState();
}

class _CreateShiftStepTabsState extends State<CreateShiftStepTabs> {
  final Map<CreateShiftStep, GlobalKey> _keys = {
    for (final step in CreateShiftStep.values) step: GlobalKey(),
  };

  @override
  void didUpdateWidget(covariant CreateShiftStepTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabContext = _keys[widget.selected]?.currentContext;
      if (tabContext == null || !tabContext.mounted) return;
      Scrollable.ensureVisible(
        tabContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final onSelected = widget.onSelected;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16),
      child: Row(
        children: [
          for (final tab in CreateShiftStep.values) ...[
            _TabChip(
              key: _keys[tab],
              tab: tab,
              selected: tab == selected,
              completed: widget.completed.contains(tab),
              onTap: onSelected == null ? null : () => onSelected(tab),
            ),
            if (tab != CreateShiftStep.values.last)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final CreateShiftStep tab;
  final bool selected;
  final bool completed;
  final VoidCallback? onTap;

  const _TabChip({
    super.key,
    required this.tab,
    required this.selected,
    required this.completed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? AppColors.primaryNavy
        : completed
            ? AppColors.successGreen
            : AppColors.textMuted;
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _TabIcon(tab: tab, color: fg),
                  if (completed)
                    Positioned(
                      right: -5,
                      bottom: -5,
                      child: Container(
                        key: ValueKey('create-shift-step-done-${tab.name}'),
                        width: ResponsiveHelper.getResponsiveSize(context, 12),
                        height: ResponsiveHelper.getResponsiveSize(context, 12),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.check_rounded,
                          size: ResponsiveHelper.getResponsiveSize(context, 8),
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: selected ? AppColors.primaryNavy : AppColors.textHeading,
                    ),
                  ),
                  Text(
                    tab.description,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 11),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  final CreateShiftStep tab;
  final Color color;

  const _TabIcon({required this.tab, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case CreateShiftStep.shiftInformation:
        return AppSvgIcon(AppAssets.calendarCheck, size: 16, color: color);
      case CreateShiftStep.staffAssignment:
        return AppSvgIcon(AppAssets.users, size: 16, color: color);
      case CreateShiftStep.openShift:
        return Icon(
          Icons.cell_tower_rounded,
          size: ResponsiveHelper.getResponsiveSize(context, 16),
          color: color,
        );
      case CreateShiftStep.recurring:
        return Icon(
          Icons.sync_rounded,
          size: ResponsiveHelper.getResponsiveSize(context, 16),
          color: color,
        );
      case CreateShiftStep.notifications:
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
