import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Bottom action bar for the "Create Incident" wizard: an outlined
/// "Save Draft" button plus a filled dark primary button that reads
/// "Continue" (with a forward-arrow) on steps 1-3, and "Submit Incident"
/// (with a paper-plane icon) on the final Evidence step.
///
/// Icon note: the save/continue-arrow/paper-plane glyphs have no matching
/// SVG in `assets/icons/*`, so this uses Material `Icons.save_outlined`,
/// `Icons.arrow_forward_rounded` and `Icons.send_rounded` as temporary
/// stand-ins.
class WizardBottomBar extends StatelessWidget {
  final bool isLastStep;
  final VoidCallback onSaveDraft;
  final VoidCallback onPrimary;

  const WizardBottomBar({
    super.key,
    required this.isLastStep,
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
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 12, bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: _BottomButton(
                  label: 'Save Draft',
                  icon: Icons.save_outlined,
                  background: AppColors.filterButtonBackground,
                  foreground: AppColors.textBody,
                  onTap: onSaveDraft,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Expanded(
                child: _BottomButton(
                  label: isLastStep ? 'Submit Incident' : 'Continue',
                  icon: isLastStep ? Icons.send_rounded : Icons.arrow_forward_rounded,
                  iconTrailing: true,
                  background: AppColors.primaryNavy,
                  foreground: Colors.white,
                  onTap: onPrimary,
                ),
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
  final IconData icon;
  final bool iconTrailing;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _BottomButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.iconTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 17), color: foreground),
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
      color: background,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 13),
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
