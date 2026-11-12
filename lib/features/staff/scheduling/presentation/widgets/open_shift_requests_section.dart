import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_shift.dart';

/// "Open Shift Requests" list from `GET /shifts?status=open`.
///
/// Web Open shifts rail: the whole card is tappable (“Click for actions” /
/// “Bid for this shift”).
class OpenShiftRequestsSection extends StatelessWidget {
  final List<StaffShift> shifts;
  final ValueChanged<StaffShift>? onRequestTap;

  const OpenShiftRequestsSection({
    super.key,
    required this.shifts,
    this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    if (shifts.isEmpty) return const SizedBox.shrink();

    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Open Shift Requests',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < shifts.length; i++) ...[
          if (i > 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _OpenShiftCard(
            shift: shifts[i],
            radius: radius,
            onRequestTap: onRequestTap,
          ),
        ],
      ],
    );
  }
}

class _OpenShiftCard extends StatelessWidget {
  final StaffShift shift;
  final double radius;
  final ValueChanged<StaffShift>? onRequestTap;

  const _OpenShiftCard({
    required this.shift,
    required this.radius,
    required this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    final canBid = onRequestTap != null;
    final bidLabel = shift.filled <= 0
        ? 'No bids yet'
        : '${shift.filled} staff ${shift.filled == 1 ? 'has' : 'have'} bid for this shift';

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: canBid ? () => onRequestTap!(shift) : null,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.activeBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        shift.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize:
                              ResponsiveHelper.getResponsiveFontSize(context, 11),
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
              Text(
                shift.dateTimeLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: AppColors.textHeading,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
              Text(
                '${shift.location} · ${shift.openSlots} open'
                '${shift.roleTag.isEmpty ? '' : ' · ${shift.roleTag}'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
              Text(
                canBid
                    ? (shift.filled <= 0
                        ? 'No bids yet'
                        : '$bidLabel. Tap to bid.')
                    : bidLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.secondaryTeal,
                ),
              ),
              if (canBid) ...[
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(context, 10),
                      ),
                      border: Border.all(color: AppColors.textHeading),
                    ),
                    child: Text(
                      'Bid for this shift',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
