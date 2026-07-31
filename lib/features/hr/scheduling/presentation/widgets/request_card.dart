import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/shift_request.dart';
import '../../scheduling_constants.dart';

const List<Color> _avatarBackgrounds = [
  AppColors.nightBackground,
  AppColors.activeBackground,
  AppColors.infoBackground,
];
const List<Color> _avatarForegrounds = [
  AppColors.nightPurple,
  AppColors.activeGreen,
  AppColors.infoBlue,
];

/// A single shift-swap request card on the Requests tab: requester avatar +
/// name + "Swap" tag + status pill, a giving/receiving date-swap row, and
/// (only for pending requests) Decline/Approve actions.
///
/// NOTE: the "Swap" arrows icon and the Decline/Approve glyphs are rendered
/// with Material Icons (`Icons.swap_horiz_rounded` / `Icons.close_rounded` /
/// `Icons.check_rounded`) as temporary stand-ins — see the feature's final
/// report for why no matching SVG could be exported from Figma for this
/// build.
class RequestCard extends StatelessWidget {
  final ShiftRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const RequestCard({super.key, required this.request, this.onApprove, this.onDecline});

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == RequestStatus.pending;
    final paletteIndex = request.staffInitials.codeUnits.fold<int>(0, (a, b) => a + b) %
        _avatarBackgrounds.length;
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, SchedulingDimens.requestAvatarSize);

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 12)),
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: _avatarBackgrounds[paletteIndex],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    request.staffInitials,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                      color: _avatarForegrounds[paletteIndex],
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              request.staffName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                          StatusBadge.chip(
                            label: 'Swap',
                            background: AppColors.infoBackground,
                            foreground: AppColors.infoBlue,
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                      Text(
                        request.timingLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge.pill(
                  label: isPending ? 'Pending' : 'Approved',
                  background: isPending ? AppColors.urgentBackground : AppColors.activeBackground,
                  foreground: isPending ? AppColors.urgentAmber : AppColors.activeGreen,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            Container(
              padding: ResponsiveHelper.getResponsivePadding(context, all: 12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusIconBoxMedium),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SwapDetail(label: 'GIVING', value: request.givingLabel, alignEnd: false),
                  ),
                  Padding(
                    padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 8),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      size: ResponsiveHelper.getResponsiveSize(context, 18),
                      color: AppColors.textFaint,
                    ),
                  ),
                  Expanded(
                    child: _SwapDetail(label: 'RECEIVING', value: request.receivingLabel, alignEnd: true),
                  ),
                ],
              ),
            ),
            if (isPending) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Decline',
                      icon: Icons.close_rounded,
                      isPrimary: false,
                      onTap: onDecline,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                  Expanded(
                    child: _ActionButton(
                      label: 'Approve',
                      icon: Icons.check_rounded,
                      isPrimary: true,
                      onTap: onApprove,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwapDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _SwapDetail({required this.label, required this.value, required this.alignEnd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9.5),
            color: AppColors.textFaint,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            color: AppColors.textBody,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.secondaryTeal : AppColors.surfaceWhite,
          border: isPrimary ? null : Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusChip),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: ResponsiveHelper.getResponsiveSize(context, 15),
              color: isPrimary ? Colors.white : AppColors.textSecondary,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: isPrimary ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
