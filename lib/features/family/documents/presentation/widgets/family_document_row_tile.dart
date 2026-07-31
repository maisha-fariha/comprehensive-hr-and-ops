import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/family_document.dart';
import '../../family_documents_constants.dart';

/// A single row in the "Documents" list: a colored file-type icon box, a
/// title + subtext line, and a trailing circular download button.
class FamilyDocumentRowTile extends StatelessWidget {
  final FamilyDocument document;
  final VoidCallback? onDownloadTap;

  const FamilyDocumentRowTile({super.key, required this.document, this.onDownloadTap});

  @override
  Widget build(BuildContext context) {
    final style = FamilyDocumentsConstants.fileTypeStyle(document.fileType);
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, AppDimens.iconBoxLarge);
    final downloadButtonSize = ResponsiveHelper.getResponsiveSize(context, AppDimens.iconBoxSmall);

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: AppDimens.cardPaddingHorizontal,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusIconBoxLarge),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              FamilyDocumentsConstants.fileTypeIcon(document.fileType),
              size: ResponsiveHelper.getResponsiveFontSize(context, AppDimens.iconMedium),
              color: style.foreground,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  document.title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                Text(
                  document.subtitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          GestureDetector(
            onTap: onDownloadTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: downloadButtonSize,
              height: downloadButtonSize,
              decoration: const BoxDecoration(
                color: AppColors.scaffoldBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              // No existing SVG matches a download glyph and the Figma
              // asset-download tool is unavailable this round (monthly
              // quota exhausted), so this uses Material
              // `Icons.download_rounded` as a temporary stand-in.
              child: Icon(
                Icons.download_rounded,
                size: ResponsiveHelper.getResponsiveFontSize(context, 18),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
