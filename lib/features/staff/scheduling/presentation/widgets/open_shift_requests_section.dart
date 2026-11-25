import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../domain/entities/staff_shift.dart';

/// Web Open shifts rail for staff: Upcoming / Past unstaffed + Bid CTA.
class OpenShiftRequestsSection extends StatefulWidget {
  final List<StaffShift> shifts;
  final ValueChanged<StaffShift>? onRequestTap;
  final bool canWrite;

  const OpenShiftRequestsSection({
    super.key,
    required this.shifts,
    this.onRequestTap,
    this.canWrite = false,
  });

  @override
  State<OpenShiftRequestsSection> createState() =>
      _OpenShiftRequestsSectionState();
}

class _OpenShiftRequestsSectionState extends State<OpenShiftRequestsSection> {
  /// Match HR Open shifts rail: Upcoming selected by default.
  bool _past = false;

  @override
  Widget build(BuildContext context) {
    if (widget.shifts.isEmpty) return const SizedBox.shrink();

    final now = TenantClock.now();
    final upcoming = <StaffShift>[];
    final past = <StaffShift>[];
    for (final shift in widget.shifts) {
      final end = shift.endAt ?? shift.startAt;
      if (end == null || !end.isBefore(now)) {
        upcoming.add(shift);
      } else {
        past.add(shift);
      }
    }
    final rows = _past ? past : upcoming;
    final canBid = widget.onRequestTap != null;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Open shifts',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                color: AppColors.textHeading,
              ),
            ),
            if (past.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${past.length} past',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Row(
          children: [
            _Tab(
              label: 'Upcoming (${upcoming.length})',
              selected: !_past,
              onTap: () => setState(() => _past = false),
            ),
            const SizedBox(width: 8),
            _Tab(
              label: 'Past unstaffed (${past.length})',
              selected: _past,
              onTap: () => setState(() => _past = true),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (rows.isEmpty)
          Text(
            _past
                ? 'No past unstaffed shifts.'
                : widget.canWrite
                    ? 'Nothing is open for bidding. Opening a shift lets staff put their name forward for it.'
                    : 'Nothing is open to bid for at the moment.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textSecondary,
            ),
          )
        else
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            _OpenShiftCard(
              shift: rows[i],
              radius: radius,
              canWrite: widget.canWrite,
              canBid: canBid,
              onRequestTap: widget.onRequestTap,
            ),
          ],
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryNavy : AppColors.filterButtonBackground,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenShiftCard extends StatelessWidget {
  final StaffShift shift;
  final double radius;
  final bool canWrite;
  final bool canBid;
  final ValueChanged<StaffShift>? onRequestTap;

  const _OpenShiftCard({
    required this.shift,
    required this.radius,
    required this.canWrite,
    required this.canBid,
    required this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    final assignedToSelf = false; // staff open list excludes assigned fills
    final bidLabel = shift.pendingBidCount <= 0
        ? 'No bids yet'
        : '${shift.pendingBidCount} staff '
            '${shift.pendingBidCount == 1 ? 'has' : 'have'} '
            'bid for this shift';

    return Material(
      color: AppColors.surfaceWhite,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              [
                shift.location,
                if (shift.openSlots > 0) '${shift.openSlots} open',
                if (shift.roleTag.isNotEmpty) shift.roleTag,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.textSecondary,
              ),
            ),
            if (canWrite) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
              Text(
                shift.pendingBidCount <= 0
                    ? 'No bids yet'
                    : '$bidLabel. Click for actions.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.secondaryTeal,
                ),
              ),
            ],
            if (canBid && !assignedToSelf) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
              if (shift.ownBidPending)
                Text(
                  'Your bid is in — waiting on a manager',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.secondaryTeal,
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onRequestTap == null
                          ? null
                          : () => onRequestTap!(shift),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(context, 10),
                      ),
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
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              12.5,
                            ),
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
