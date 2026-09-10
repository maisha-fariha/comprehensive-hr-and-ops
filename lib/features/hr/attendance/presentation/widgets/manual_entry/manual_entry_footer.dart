import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';

class ManualEntryFooter extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool isSubmitting;

  const ManualEntryFooter({
    super.key,
    this.onCancel,
    this.onSave,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 420;
    final saveEnabled = onSave != null && !isSubmitting;
    final cancelEnabled = onCancel != null && !isSubmitting;

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

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FooterButton(
          label: 'Cancel',
          filled: false,
          onTap: cancelEnabled ? onCancel : null,
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        _FooterButton(
          label: isSubmitting ? 'Saving…' : 'Save entry',
          filled: true,
          isLoading: isSubmitting,
          onTap: saveEnabled ? onSave : null,
        ),
      ],
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
                        Expanded(
                          child: _FooterButton(
                            label: 'Cancel',
                            filled: false,
                            onTap: cancelEnabled ? onCancel : null,
                            expanded: true,
                          ),
                        ),
                        SizedBox(
                          width:
                              ResponsiveHelper.getResponsiveWidth(context, 10),
                        ),
                        Expanded(
                          child: _FooterButton(
                            label: isSubmitting ? 'Saving…' : 'Save entry',
                            filled: true,
                            isLoading: isSubmitting,
                            onTap: saveEnabled ? onSave : null,
                            expanded: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    requiredHint,
                    const Spacer(),
                    actions,
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
