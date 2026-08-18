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
          _WizardStepBar(
            currentIndex: currentIndex,
            onStepTap: onStepTap,
          ),
        ],
      ),
    );
  }
}

class _WizardStepBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<IncidentCreationStep>? onStepTap;

  const _WizardStepBar({
    required this.currentIndex,
    this.onStepTap,
  });

  static const Color _inactiveCircle = Color(0xFFEDF2F7);
  static const Color _inactiveContent = Color(0xFF94A3B8);
  static const Color _connector = Color(0xFFDDE3EA);
  static const Color _activeHalo = Color(0xFFE8EEF4);
  static const Color _completedCircle = Color(0xFFDFF3EE);
  static const Color _completedContent = Color(0xFF0E7C7B);

  @override
  Widget build(BuildContext context) {
    final outerSize = ResponsiveHelper.getResponsiveSize(context, 36);
    final lineTop = (outerSize - 1.5) / 2;

    return SizedBox(
      height: outerSize + ResponsiveHelper.getResponsiveHeight(context, 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stepCount = _stepLabels.length;
          final slotWidth = constraints.maxWidth / stepCount;

          return Stack(
            children: [
              // Single connector behind circles (circles cover the segment under them).
              Positioned(
                top: lineTop,
                left: slotWidth / 2,
                right: slotWidth / 2,
                child: Container(height: 1.5, color: _connector),
              ),
              Row(
                children: [
                  for (var i = 0; i < stepCount; i++)
                    Expanded(
                      child: _StepCircle(
                        index: i,
                        label: _stepLabels[i],
                        isActive: i == currentIndex,
                        isCompleted: i < currentIndex,
                        outerSize: outerSize,
                        onTap: onStepTap == null
                            ? null
                            : () => onStepTap!(IncidentCreationStep.values[i]),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int index;
  final String label;
  final bool isCompleted;
  final bool isActive;
  final double outerSize;
  final VoidCallback? onTap;

  const _StepCircle({
    required this.index,
    required this.label,
    required this.isCompleted,
    required this.isActive,
    required this.outerSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = ResponsiveHelper.getResponsiveSize(context, 28);
    final haloPad = (outerSize - innerSize) / 2;

    final Widget circle;
    if (isActive) {
      // Active: light outer ring + solid navy inner circle.
      circle = Container(
        width: outerSize,
        height: outerSize,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: _WizardStepBar._activeHalo,
          shape: BoxShape.circle,
        ),
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: const BoxDecoration(
            color: AppColors.primaryNavy,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      );
    } else if (isCompleted) {
      // Completed: mint circle + teal checkmark (reference).
      circle = Padding(
        padding: EdgeInsets.all(haloPad),
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: const BoxDecoration(
            color: _WizardStepBar._completedCircle,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.check_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 16),
            color: _WizardStepBar._completedContent,
          ),
        ),
      );
    } else {
      // Pending: light grey-blue fill + muted number.
      circle = Padding(
        padding: EdgeInsets.all(haloPad),
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: const BoxDecoration(
            color: _WizardStepBar._inactiveCircle,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: _WizardStepBar._inactiveContent,
              height: 1,
            ),
          ),
        ),
      );
    }

    final Color labelColor;
    final FontWeight labelWeight;
    if (isCompleted) {
      labelColor = _WizardStepBar._completedContent;
      labelWeight = FontWeight.w700;
    } else if (isActive) {
      labelColor = AppColors.primaryNavy;
      labelWeight = FontWeight.w700;
    } else {
      labelColor = _WizardStepBar._inactiveContent;
      labelWeight = FontWeight.w500;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: labelWeight,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: labelColor,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
