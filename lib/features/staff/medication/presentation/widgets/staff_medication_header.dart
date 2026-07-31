import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// The flat white app-bar-style header shared by every Staff Medication
/// tab: a back chevron and the "Medication MAR" title centered between it
/// and a symmetric trailing spacer.
///
/// NOTE: there is no matching back-chevron SVG in
/// `assets/icons/{dashboard,common,nav}`, and the Figma asset-download tool
/// is unavailable this round, so `Icons.arrow_back_ios_new_rounded` is used
/// as a placeholder — matching the existing precedent in
/// `lib/features/hr/incidents/presentation/widgets/wizard_header.dart`.
class StaffMedicationHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackTap;

  const StaffMedicationHeader({super.key, required this.title, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 32);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12, top: 8, bottom: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 18),
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              SizedBox(width: buttonSize, height: buttonSize),
            ],
          ),
        ),
      ),
    );
  }
}
