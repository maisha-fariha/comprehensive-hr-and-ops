import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Bottom action bar for the "Create Incident" wizard: an outlined
/// "Save Draft" button plus a filled dark primary button that reads
/// "Continue" (with a forward-arrow) on steps 1-3, and "Submit Incident"
/// (with a paper-plane icon) on the final Evidence step.
///
/// Icons: `save.svg` / `submit.svg` from `assets/icons/incidents`. Continue
/// arrow has no matching asset, so Material `Icons.arrow_forward_rounded`
/// stays as-is.
class WizardBottomBar extends StatelessWidget {
  final String progressLabel;
  final String primaryLabel;
  final bool primaryIsSubmit;
  final VoidCallback? onCancel;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onPrimary;

  const WizardBottomBar({
    super.key,
    required this.progressLabel,
    required this.primaryLabel,
    required this.primaryIsSubmit,
    required this.onCancel,
    required this.onSaveDraft,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
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
            horizontal: 16,
            top: 10,
            bottom: 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progressLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
              Row(
                children: [
                  Expanded(
                    child: _BottomButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      background: AppColors.surfaceWhite,
                      foreground: AppColors.textBody,
                      outlined: true,
                      onTap: onCancel,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                  Expanded(
                    child: _BottomButton(
                      label: 'Save Draft',
                      svgAsset: 'assets/icons/incidents/save.svg',
                      background: AppColors.filterButtonBackground,
                      foreground: AppColors.textBody,
                      onTap: onSaveDraft,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                  Expanded(
                    flex: 2,
                    child: _BottomButton(
                      label: primaryLabel,
                      svgAsset: primaryIsSubmit ? 'assets/icons/incidents/submit.svg' : null,
                      icon: primaryIsSubmit ? null : Icons.arrow_forward_rounded,
                      iconTrailing: !primaryIsSubmit,
                      background: AppColors.primaryNavy,
                      foreground: Colors.white,
                      onTap: onPrimary,
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

class _BottomButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? svgAsset;
  final bool iconTrailing;
  final Color background;
  final Color foreground;
  final bool outlined;
  final VoidCallback? onTap;

  const _BottomButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.icon,
    this.svgAsset,
    this.iconTrailing = false,
    this.outlined = false,
  }) : assert(icon != null || svgAsset != null);

  @override
  Widget build(BuildContext context) {
    final iconWidget = svgAsset != null
        ? AppSvgIcon(svgAsset!, size: 17, color: foreground)
        : Icon(
            icon,
            size: ResponsiveHelper.getResponsiveSize(context, 17),
            color: foreground,
          );

    final children = [
      iconWidget,
      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
            color: foreground,
          ),
        ),
      ),
    ];

    return Material(
      color: onTap == null ? background.withValues(alpha: 0.55) : background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 13),
        ),
        side: outlined
            ? const BorderSide(color: AppColors.cardBorder)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 13),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: iconTrailing ? children.reversed.toList() : children,
          ),
        ),
      ),
    );
  }
}
