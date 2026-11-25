import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_shift.dart';

/// Web scheduling rail — "Shifts you can swap" (eligible upcoming only).
class ShiftsYouCanSwapSection extends StatelessWidget {
  final List<StaffShift> shifts;
  final ValueChanged<StaffShift>? onRequestSwap;

  const ShiftsYouCanSwapSection({
    super.key,
    required this.shifts,
    this.onRequestSwap,
  });

  @override
  Widget build(BuildContext context) {
    if (onRequestSwap == null) return const SizedBox.shrink();

    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final eligible = [for (final shift in shifts) if (shift.canRequestSwap) shift];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Shifts you can swap',
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
        Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: eligible.isEmpty
              ? Text(
                  'Nothing of yours this week is eligible for a swap.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textMuted,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < eligible.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height:
                              ResponsiveHelper.getResponsiveHeight(context, 16),
                          color: AppColors.cardBorder,
                        ),
                      _SwapEligibleRow(
                        shift: eligible[i],
                        onRequest: () => onRequestSwap!(eligible[i]),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SwapEligibleRow extends StatelessWidget {
  final StaffShift shift;
  final VoidCallback onRequest;

  const _SwapEligibleRow({
    required this.shift,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shift.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${shift.dateTimeLabel} · ${shift.location}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          key: ValueKey('swap-eligible-${shift.id}'),
          onTap: onRequest,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.secondaryTeal),
            ),
            child: Text(
              'Request swap',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.secondaryTeal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
