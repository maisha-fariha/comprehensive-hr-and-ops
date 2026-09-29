import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/errors/app_snackbar.dart';

/// Witness statements block (web parity). Take-statement is mobile-unavailable.
class IncidentWitnessStatementsSection extends StatelessWidget {
  final List<String> witnessNames;

  static const String _emptyCopy =
      'None recorded. A name on its own is not an account of what happened.';

  const IncidentWitnessStatementsSection({
    super.key,
    this.witnessNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

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
            'Witness Statements',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(
            _emptyCopy,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (witnessNames.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              'Recorded names',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
            for (final name in witnessNames)
              Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveHelper.getResponsiveHeight(context, 4),
                ),
                child: Text(
                  '• $name',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                AppSnackbar.show(
                  'Unavailable',
                  'Not available on mobile yet',
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryTeal,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Take statement',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
