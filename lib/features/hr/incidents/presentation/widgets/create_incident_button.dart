import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Full-width filled teal "+ Create Incident" button pinned near the bottom
/// of every Incidents list tab (Open/Under Review/Closed all share it).
///
/// Icon note: the leading "+" has no matching SVG in `assets/icons/*`, so
/// this uses the built-in Material `Icons.add` as a temporary stand-in.
class CreateIncidentButton extends StatelessWidget {
  final VoidCallback onTap;

  const CreateIncidentButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.secondaryTeal,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 16),
          ),
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: ResponsiveHelper.getResponsiveSize(context, 20), color: Colors.white),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
                Text(
                  'Create Incident',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Web "Export List" control — outlined navy/secondary action above Create.
class ExportListButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const ExportListButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 16),
          ),
          child: Container(
            padding: ResponsiveHelper.getResponsivePadding(context, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 16),
              ),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveSize(context, 18),
                    height: ResponsiveHelper.getResponsiveSize(context, 18),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryNavy,
                    ),
                  )
                else
                  Icon(
                    Icons.file_download_outlined,
                    size: ResponsiveHelper.getResponsiveSize(context, 20),
                    color: AppColors.primaryNavy,
                  ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
                Text(
                  isLoading ? 'Preparing…' : 'Export List',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
