import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
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
  final VoidCallback? onPreviewTap;
  final VoidCallback? onSignTap;
  final bool isDownloading;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _metaColor = Color(0xFF71839B);
  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);
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
    this.onPreviewTap,
    this.onSignTap,
    this.isDownloading = false,
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
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);
    final fromFamily = document.category.isNotEmpty;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontFamily: 'Outfit',
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
                      '${document.updatedAt == null ? 'On file' : WebFormat.date(document.updatedAt)} • ${document.kindLabel}',
                      maxLines: 2,
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
            ],
          ),
          if (document.signatureRequired) ...[
            const SizedBox(height: 10),
            if (document.signatureAcknowledgedAt != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'You signed this on ${WebFormat.date(document.signatureAcknowledgedAt)}.',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12.5,
                    color: AppColors.successGreen,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                decoration: BoxDecoration(
                  color: AppColors.urgentBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.urgentAmber.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The care home asks you to read this and confirm you agree${document.signatureDueAt == null ? '' : ' by ${WebFormat.date(document.signatureDueAt)}'}.',
                      style: const TextStyle(fontFamily: 'Manrope', fontSize: 12.5),
                    ),
                    if (onSignTap != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onSignTap,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.secondaryTeal,
                            textStyle: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          icon: const Icon(Icons.draw_outlined, size: 16),
                          label: const Text('Sign Document'),
                        ),
                      ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE8EDF2))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: fromFamily
                        ? const Color(0xFFF0ECFB)
                        : const Color(0xFFE8F4FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    document.sourceLabel,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: fromFamily
                          ? const Color(0xFF6A4BC7)
                          : AppColors.infoBlue,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onPreviewTap,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _titleColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('Preview'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: isDownloading ? null : onDownloadTap,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.secondaryTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  icon: isDownloading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.secondaryTeal,
                          ),
                        )
                      : const AppSvgIcon(_downloadAsset, size: 14),
                  label: Text(isDownloading ? 'Downloading…' : 'Download'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
