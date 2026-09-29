import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/incident_detail.dart';

/// Web-parity header: title, `#id · client · residence`, status pill.
class IncidentWebHeaderCard extends StatelessWidget {
  final IncidentDetail detail;

  static const Color _statusBackground = Color(0xFFFEF3C7);
  static const Color _statusForeground = Color(0xFFD97706);

  const IncidentWebHeaderCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 3)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              color: AppColors.textHeading,
              height: 1.25,
            ),
          ),
          if (detail.headerMeta.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
            Text(
              detail.headerMeta,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _statusBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: ResponsiveHelper.getResponsiveSize(context, 7),
                    height: ResponsiveHelper.getResponsiveSize(context, 7),
                    decoration: const BoxDecoration(
                      color: _statusForeground,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveWidth(context, 6),
                  ),
                  Text(
                    detail.statusLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: _statusForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
