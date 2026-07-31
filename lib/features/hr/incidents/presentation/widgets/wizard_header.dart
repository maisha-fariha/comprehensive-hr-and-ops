import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/incidents_enums.dart';

const List<String> _stepLabels = ['Details', 'People', 'Investigate', 'Evidence'];

/// Header for the "Create Incident" wizard: back/close buttons, title +
/// draft id, and the 1-2-3-4 step progress indicator.
///
/// Icon note: the back chevron and close "X" have no matching SVG in
/// `assets/icons/*`, so this uses Material `Icons.arrow_back_ios_new_rounded`
/// and `Icons.close_rounded` as temporary stand-ins.
class WizardHeader extends StatelessWidget {
  final IncidentCreationStep currentStep;
  final String draftId;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final ValueChanged<IncidentCreationStep>? onStepTap;

  const WizardHeader({
    super.key,
    required this.currentStep,
    required this.draftId,
    required this.onBack,
    required this.onClose,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 38);
    final currentIndex = IncidentCreationStep.values.indexOf(currentStep);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 18),
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'New Incident',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      'Draft · $draftId',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.searchBorder),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 11),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 19),
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          Row(
            children: [
              for (var i = 0; i < _stepLabels.length; i++) ...[
                if (i != 0)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      color: i <= currentIndex ? AppColors.activeGreen : AppColors.cardBorder,
                    ),
                  ),
                _StepCircle(
                  index: i,
                  label: _stepLabels[i],
                  isCompleted: i < currentIndex,
                  isActive: i == currentIndex,
                  onTap: onStepTap == null ? null : () => onStepTap!(IncidentCreationStep.values[i]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int index;
  final String label;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback? onTap;

  const _StepCircle({
    required this.index,
    required this.label,
    required this.isCompleted,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 30);
    final Color circleColor;
    final Color textColor;
    if (isCompleted) {
      circleColor = AppColors.activeBackground;
      textColor = AppColors.activeGreen;
    } else if (isActive) {
      circleColor = AppColors.primaryNavy;
      textColor = Colors.white;
    } else {
      circleColor = AppColors.dividerLight;
      textColor = AppColors.textFaint;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: isCompleted
                ? Icon(Icons.check_rounded, size: ResponsiveHelper.getResponsiveSize(context, 16), color: textColor)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: textColor,
                    ),
                  ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
              color: isActive
                  ? AppColors.textHeading
                  : (isCompleted ? AppColors.activeGreen : AppColors.textFaint),
            ),
          ),
        ],
      ),
    );
  }
}
