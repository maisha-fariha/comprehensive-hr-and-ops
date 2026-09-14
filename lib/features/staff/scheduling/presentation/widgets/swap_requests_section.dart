import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_shift_swap.dart';

/// "My Swap Requests" — list from `GET /shift-swaps?mine=true`.
class SwapRequestsSection extends StatelessWidget {
  final List<StaffShiftSwap> swaps;
  final ValueChanged<StaffShiftSwap>? onAccept;
  final ValueChanged<StaffShiftSwap>? onDecline;
  final ValueChanged<StaffShiftSwap>? onCancel;

  const SwapRequestsSection({
    super.key,
    required this.swaps,
    this.onAccept,
    this.onDecline,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (swaps.isEmpty) return const SizedBox.shrink();

    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'My Swap Requests',
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
        for (var i = 0; i < swaps.length; i++) ...[
          if (i > 0)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _SwapCard(
            swap: swaps[i],
            radius: radius,
            onAccept: onAccept,
            onDecline: onDecline,
            onCancel: onCancel,
          ),
        ],
      ],
    );
  }
}

class _SwapCard extends StatelessWidget {
  final StaffShiftSwap swap;
  final double radius;
  final ValueChanged<StaffShiftSwap>? onAccept;
  final ValueChanged<StaffShiftSwap>? onDecline;
  final ValueChanged<StaffShiftSwap>? onCancel;

  const _SwapCard({
    required this.swap,
    required this.radius,
    this.onAccept,
    this.onDecline,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${swap.kindLabel} · ${swap.counterpartName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Text(
                swap.statusLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: AppColors.secondaryTeal,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Text(
            swap.fromShiftLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          if (swap.toShiftLabel != null) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
            Text(
              'For · ${swap.toShiftLabel}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (swap.note != null && swap.note!.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
            Text(
              swap.note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (swap.canRespond || swap.canCancel) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Row(
              children: [
                if (swap.canRespond) ...[
                  _ActionChip(
                    label: 'Decline',
                    filled: false,
                    onTap: onDecline == null ? null : () => onDecline!(swap),
                  ),
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveWidth(context, 8),
                  ),
                  _ActionChip(
                    label: 'Accept',
                    filled: true,
                    onTap: onAccept == null ? null : () => onAccept!(swap),
                  ),
                ] else if (swap.canCancel)
                  _ActionChip(
                    label: 'Cancel',
                    filled: false,
                    onTap: onCancel == null ? null : () => onCancel!(swap),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.label,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: filled ? AppColors.secondaryTeal : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 10),
          ),
          border: Border.all(color: AppColors.secondaryTeal),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: filled ? Colors.white : AppColors.secondaryTeal,
          ),
        ),
      ),
    );
  }
}
