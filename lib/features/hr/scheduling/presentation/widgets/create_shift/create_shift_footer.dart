import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Wizard footer: Cancel/Back, optional Draft / Delete / Publish, and Next/Create.
class CreateShiftFooter extends StatelessWidget {
  final bool isFirstStep;
  final bool isLastStep;
  final bool isSubmitting;
  final int plannedOccurrences;
  final VoidCallback? onCancel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  /// Create only: web "Save as Draft".
  final VoidCallback? onSaveDraft;

  /// Edit draft only: web "Publish Shift" (filled primary).
  final VoidCallback? onPublish;

  /// Edit only: delete this shift.
  final VoidCallback? onDelete;

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
    this.onSaveDraft,
    this.onPublish,
    this.onDelete,
    this.isEdit = false,
  });

  String get _submitLabel {
    if (isSubmitting) return 'Saving…';
    if (plannedOccurrences > 1) return 'Create $plannedOccurrences shifts';
    // Web edit-draft footer: "Save as Draft" keeps status; Publish promotes.
    if (isEdit && onPublish != null) return 'Save as Draft';
    return isEdit ? 'Save changes' : 'Create shift';
  }

  @override
  Widget build(BuildContext context) {
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

    // Web: only one filled primary. When Publish Shift is present it is that
    // primary — Next / Save as Draft stay outlined so they do not compete.
    final primaryFilled = onPublish == null;

    final secondary = isFirstStep
        ? _FooterButton(
            key: const ValueKey('create-shift-cancel'),
            label: 'Cancel',
            filled: false,
            expanded: true,
            onTap: isSubmitting ? null : onCancel,
          )
        : _FooterButton(
            key: const ValueKey('create-shift-back'),
            label: 'Back',
            filled: false,
            expanded: true,
            onTap: isSubmitting ? null : onBack,
          );

    final primary = isLastStep
        ? _FooterButton(
            key: const ValueKey('create-shift-submit'),
            label: _submitLabel,
            filled: primaryFilled,
            expanded: true,
            isLoading: isSubmitting,
            onTap: isSubmitting ? null : onSubmit,
          )
        : _FooterButton(
            key: const ValueKey('create-shift-next'),
            label: 'Next',
            filled: primaryFilled,
            expanded: true,
            onTap: onNext,
          );

    final draft = !isEdit && onSaveDraft != null
        ? _FooterButton(
            key: const ValueKey('create-shift-draft'),
            label: isSubmitting ? 'Saving…' : 'Save as Draft',
            filled: false,
            expanded: true,
            onTap: isSubmitting ? null : onSaveDraft,
          )
        : null;

    // Web Publish is the primary action for drafts (filled navy).
    final publish = isEdit && onPublish != null
        ? _FooterButton(
            key: const ValueKey('create-shift-publish'),
            label: isSubmitting ? 'Publishing…' : 'Publish Shift',
            filled: true,
            expanded: true,
            onTap: isSubmitting ? null : onPublish,
          )
        : null;

    final delete = isEdit && onDelete != null
        ? _FooterButton(
            key: const ValueKey('create-shift-delete'),
            label: 'Delete',
            filled: false,
            expanded: true,
            danger: true,
            onTap: isSubmitting ? null : onDelete,
          )
        : null;

    final gap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 10),
    );
    final hGap = SizedBox(
      width: ResponsiveHelper.getResponsiveWidth(context, 10),
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
          // Always stack on phone — a single Row overflows when Delete +
          // Publish Shift + Cancel + Next share one line (~147px).
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              requiredHint,
              gap,
              if (delete != null || publish != null || draft != null) ...[
                Row(
                  children: [
                    if (delete != null) Expanded(child: delete),
                    if (delete != null && (publish != null || draft != null))
                      hGap,
                    if (publish != null) Expanded(child: publish),
                    if (publish != null && draft != null) hGap,
                    if (draft != null) Expanded(child: draft),
                  ],
                ),
                gap,
              ],
              Row(
                children: [
                  Expanded(child: secondary),
                  hGap,
                  Expanded(child: primary),
                ],
              ),
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
  final bool danger;
  final VoidCallback? onTap;

  const _FooterButton({
    super.key,
    required this.label,
    required this.filled,
    this.onTap,
    this.expanded = false,
    this.isLoading = false,
    this.danger = false,
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
        : danger
            ? (enabled
                ? AppColors.criticalRed
                : AppColors.criticalRed.withValues(alpha: 0.45))
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
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
            border: filled
                ? null
                : Border.all(
                    color: danger
                        ? AppColors.criticalRed.withValues(alpha: 0.35)
                        : AppColors.searchBorder,
                  ),
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
                  textAlign: TextAlign.center,
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
