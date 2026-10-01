import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Wizard footer: "* Required fields", Cancel/Back and Next/Create.
class CreateShiftFooter extends StatelessWidget {
  final bool isFirstStep;
  final bool isLastStep;
  final bool isSubmitting;
  final int plannedOccurrences;
  final VoidCallback? onCancel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  /// Edit Shift mode: the submit reads "Save changes".
  final bool isEdit;

  const CreateShiftFooter({
    super.key,
    required this.isFirstStep,
    required this.isLastStep,
    this.isSubmitting = false,
    this.plannedOccurrences = 1,
    this.onCancel,
    this.onBack,
    this.onNext,
    this.onSubmit,
    this.isEdit = false,
  });

  String get _submitLabel {
    if (isSubmitting) return 'Saving…';
    if (plannedOccurrences > 1) return 'Create $plannedOccurrences shifts';
    return isEdit ? 'Save changes' : 'Create shift';
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 420;
    final requiredHint = RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
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
    );

    Widget secondary({bool expanded = false}) => isFirstStep
        ? _FooterButton(
            key: const ValueKey('create-shift-cancel'),
            label: 'Cancel',
            filled: false,
            expanded: expanded,
            onTap: isSubmitting ? null : onCancel,
          )
        : _FooterButton(
            key: const ValueKey('create-shift-back'),
            label: 'Back',
            filled: false,
            expanded: expanded,
            onTap: isSubmitting ? null : onBack,
          );

    Widget primary({bool expanded = false}) => isLastStep
        ? _FooterButton(
            key: const ValueKey('create-shift-submit'),
            label: _submitLabel,
            filled: true,
            expanded: expanded,
            isLoading: isSubmitting,
            onTap: isSubmitting ? null : onSubmit,
          )
        : _FooterButton(
            key: const ValueKey('create-shift-next'),
            label: 'Next',
            filled: true,
            expanded: expanded,
            onTap: onNext,
          );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 20,
            top: 12,
            bottom: 12,
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    requiredHint,
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 12),
                    ),
                    Row(
                      children: [
                        Expanded(child: secondary(expanded: true)),
                        SizedBox(
                          width: ResponsiveHelper.getResponsiveWidth(context, 10),
                        ),
                        Expanded(child: primary(expanded: true)),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    requiredHint,
                    const Spacer(),
                    secondary(),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 10),
                    ),
                    primary(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool expanded;
  final bool isLoading;
  final VoidCallback? onTap;

  const _FooterButton({
    super.key,
    required this.label,
    required this.filled,
    this.onTap,
    this.expanded = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final background = filled
        ? (enabled
            ? AppColors.primaryNavy
            : AppColors.primaryNavy.withValues(alpha: 0.55))
        : AppColors.surfaceWhite;
    final foreground = filled
        ? Colors.white
        : (enabled
            ? AppColors.textHeading
            : AppColors.textHeading.withValues(alpha: 0.45));

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        child: Container(
          width: expanded ? double.infinity : null,
          alignment: Alignment.center,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
            border: filled ? null : Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: ResponsiveHelper.getResponsiveSize(context, 16),
                  height: ResponsiveHelper.getResponsiveSize(context, 16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
