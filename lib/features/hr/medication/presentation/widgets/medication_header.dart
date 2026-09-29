import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Medication MAR app bar — web PageHeader parity:
/// back (module navigation), title, and Export MAR action.
class MedicationHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBackTap;
  final VoidCallback? onExportTap;
  final bool isExporting;

  const MedicationHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBackTap,
    this.onExportTap,
    this.isExporting = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final buttonRadius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              _HeaderIconButton(
                size: buttonSize,
                radius: buttonRadius,
                onTap: onBackTap ?? () => Get.back(),
                child: Transform.rotate(
                  angle: 3.14159,
                  child: const AppSvgIcon(
                    AppAssets.chevronRight,
                    size: 18,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 17),
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              _ExportMarChip(
                isLoading: isExporting,
                onTap: isExporting ? null : onExportTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportMarChip extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _ExportMarChip({required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        key: const Key('hr-mar-export'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 10,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: ResponsiveHelper.getResponsiveSize(context, 14),
                  height: ResponsiveHelper.getResponsiveSize(context, 14),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondaryTeal,
                  ),
                )
              else
                Icon(
                  Icons.file_download_outlined,
                  size: ResponsiveHelper.getResponsiveSize(context, 16),
                  color: AppColors.secondaryTeal,
                ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              Text(
                isLoading ? 'Exporting…' : 'Export MAR',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.secondaryTeal,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final double size;
  final double radius;
  final VoidCallback? onTap;
  final Widget child;

  const _HeaderIconButton({
    required this.size,
    required this.radius,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
