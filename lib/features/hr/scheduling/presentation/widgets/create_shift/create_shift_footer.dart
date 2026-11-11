import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Which footer action currently owns the loading indicator (Bug Report 002).
abstract final class CreateShiftBusyAction {
  static const submit = 'submit';
  static const draft = 'draft';
  static const publish = 'publish';
  static const delete = 'delete';
}

/// Wizard footer: Cancel/Back, optional Draft / Delete / Publish, and Next/Create.
///
/// Only the active [busyAction] shows a spinner / “Saving…” label. Sibling
/// buttons disable so double-submit is blocked, but they keep their idle labels.
class CreateShiftFooter extends StatelessWidget {
  final bool isFirstStep;
  final bool isLastStep;
  /// One of [CreateShiftBusyAction], or null when idle.
  final String? busyAction;
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
    this.busyAction,
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

  bool get _locked => busyAction != null;

  String get _submitIdleLabel {
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
    final submitBusy = busyAction == CreateShiftBusyAction.submit;
    final draftBusy = busyAction == CreateShiftBusyAction.draft;
    final publishBusy = busyAction == CreateShiftBusyAction.publish;

    final secondary = isFirstStep
        ? _FooterButton(
            key: const ValueKey('create-shift-cancel'),
            label: 'Cancel',
            filled: false,
            expanded: true,
            onTap: _locked ? null : onCancel,
          )
        : _FooterButton(
            key: const ValueKey('create-shift-back'),
            label: 'Back',
            filled: false,
            expanded: true,
            onTap: _locked ? null : onBack,
          );

    final primary = isLastStep
        ? _FooterButton(
            key: const ValueKey('create-shift-submit'),
            label: submitBusy ? 'Saving…' : _submitIdleLabel,
            filled: primaryFilled,
            expanded: true,
            isLoading: submitBusy,
            onTap: _locked ? null : onSubmit,
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
            label: draftBusy ? 'Saving…' : 'Save as Draft',
            filled: false,
            expanded: true,
            isLoading: draftBusy,
            onTap: _locked ? null : onSaveDraft,
          )
        : null;

    // Web Publish is the primary action for drafts (filled navy).
    final publish = isEdit && onPublish != null
        ? _FooterButton(
            key: const ValueKey('create-shift-publish'),
            label: publishBusy ? 'Publishing…' : 'Publish Shift',
            filled: true,
            expanded: true,
            isLoading: publishBusy,
            onTap: _locked ? null : onPublish,
          )
        : null;

    final delete = isEdit && onDelete != null
        ? _FooterButton(
            key: const ValueKey('create-shift-delete'),
            label: busyAction == CreateShiftBusyAction.delete
                ? 'Deleting…'
                : 'Delete',
            filled: false,
            expanded: true,
            danger: true,
            isLoading: busyAction == CreateShiftBusyAction.delete,
            onTap: _locked ? null : onDelete,
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
