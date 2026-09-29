import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Status badge + acknowledged date (web parity).
class IncidentStatusAckSection extends StatelessWidget {
  final String statusLabel;
  final bool acknowledged;
  final String? acknowledgedAtLabel;

  static const Color _statusBackground = Color(0xFFFEF3C7);
  static const Color _statusForeground = Color(0xFFD97706);

  const IncidentStatusAckSection({
    super.key,
    required this.statusLabel,
    this.acknowledged = false,
    this.acknowledgedAtLabel,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final ackLabel = acknowledgedAtLabel?.trim();

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Container(
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
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                Text(
                  statusLabel,
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
          if (acknowledged && ackLabel != null && ackLabel.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: ResponsiveHelper.getResponsiveSize(context, 16),
                  color: const Color(0xFF059669),
                ),
                SizedBox(
                  width: ResponsiveHelper.getResponsiveWidth(context, 6),
                ),
                Expanded(
                  child: Text(
                    'Acknowledged $ackLabel',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
