import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_document.dart';
import '../../domain/entities/family_document_enums.dart';

class _DocVisual {
  final String asset;
  final Color background;
  final Color foreground;

  const _DocVisual({
    required this.asset,
    required this.background,
    required this.foreground,
  });
}

/// A single Documents list card: typed icon badge, title + meta, download.
class FamilyDocumentRowTile extends StatelessWidget {
  final FamilyDocument document;
  final VoidCallback? onDownloadTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _metaColor = Color(0xFF71839B);
  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);
  static const Color _downloadBg = Color(0xFFF1F5F9);
  static const Color _downloadIcon = Color(0xFF0E7C7B);

  static const String _summaryIcon = 'assets/icons/family_more/summary.svg';
  static const String _calendarIcon = 'assets/icons/family_more/calendar.svg';
  static const String _imageIcon = 'assets/icons/family_more/image.svg';
  static const String _downloadAsset = 'assets/icons/family_more/download.svg';

  static const _DocVisual _pdfPink = _DocVisual(
    asset: _summaryIcon,
    background: Color(0xFFFCEDED),
    foreground: Color(0xFFD64545),
  );
  static const _DocVisual _pdfOrange = _DocVisual(
    asset: _summaryIcon,
    background: Color(0xFFFBF0E4),
    foreground: Color(0xFFD98324),
  );
  static const _DocVisual _pdfPurple = _DocVisual(
    asset: _summaryIcon,
    background: Color(0xFFF0ECFB),
    foreground: Color(0xFF6A4BC7),
  );
  static const _DocVisual _calendarPink = _DocVisual(
    asset: _calendarIcon,
    background: Color(0xFFFCEDED),
    foreground: Color(0xFFD64545),
  );
  static const _DocVisual _jpgOrange = _DocVisual(
    asset: _imageIcon,
    background: Color(0xFFFBF0E4),
    foreground: Color(0xFFD98324),
  );

  const FamilyDocumentRowTile({
    super.key,
    required this.document,
    this.onDownloadTap,
  });

  _DocVisual get _visual {
    if (document.fileType == FamilyDocumentFileType.jpg) {
      return _jpgOrange;
    }
    final category = document.category.toLowerCase();
    if (category.contains('calendar') || category.contains('activ')) {
      return _calendarPink;
    }
    if (category.contains('policy') || category.contains('visit')) {
      return _pdfOrange;
    }
    if (category.contains('emergency') || category.contains('contact')) {
      return _pdfPurple;
    }
    return _pdfPink;
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final downloadSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _shadow.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
          ),
          BoxShadow(
            color: _shadow.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 6)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: visual.background,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(
                  visual.asset,
                  size: 22,
                  color: visual.foreground,
                ),
                Text(
                  document.fileType.label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      7,
                    ),
                    color: visual.foreground,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  document.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      14.5,
                    ),
                    color: _titleColor,
                    height: 1.25,
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 4),
                ),
                Text(
                  document.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      12,
                    ),
                    color: _metaColor,
                    height: 1.25,
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
              width: downloadSize,
              height: downloadSize,
              decoration: BoxDecoration(
                color: _downloadBg,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Color(0xFFE7EBF0), width: 1)
              ),
              alignment: Alignment.center,
              child: const AppSvgIcon(
                _downloadAsset,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
