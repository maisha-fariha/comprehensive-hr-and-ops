import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/entities/calendar_shift.dart';
import '../../domain/entities/shift_bid.dart';
import '../controllers/scheduling_controller.dart';

/// Web open-shift “Click for actions”: list pending bids and Accept.
Future<void> showOpenShiftBidsSheet({
  required BuildContext context,
  required SchedulingController controller,
  required CalendarShift shift,
  VoidCallback? onEditShift,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _OpenShiftBidsSheet(
      controller: controller,
      shift: shift,
      onEditShift: onEditShift,
    ),
  );
}

class _OpenShiftBidsSheet extends StatefulWidget {
  final SchedulingController controller;
  final CalendarShift shift;
  final VoidCallback? onEditShift;

  const _OpenShiftBidsSheet({
    required this.controller,
    required this.shift,
    this.onEditShift,
  });

  @override
  State<_OpenShiftBidsSheet> createState() => _OpenShiftBidsSheetState();
}

class _OpenShiftBidsSheetState extends State<_OpenShiftBidsSheet> {
  late List<ShiftBid> _bids;
  String? _busyBidId;

  @override
  void initState() {
    super.initState();
    _bids = List<ShiftBid>.from(widget.shift.pendingBids);
  }

  Future<void> _accept(ShiftBid bid) async {
    if (_busyBidId != null) return;
    setState(() => _busyBidId = bid.bidId);
    final ok = await widget.controller.acceptShiftBid(
      shiftId: widget.shift.id,
      bidId: bid.bidId,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busyBidId = null);
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.shift.title ?? '').trim().isEmpty
        ? widget.shift.name
        : widget.shift.title!;
    return SafeArea(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 20,
          top: 12,
          bottom: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                color: AppColors.textHeading,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
            Text(
              _bids.isEmpty
                  ? 'No bids yet'
                  : '${_bids.length} staff ${_bids.length == 1 ? 'has' : 'have'} bid for this shift',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            if (_bids.isEmpty)
              const Text(
                'Staff bids will show here for you to accept.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5,
                  color: AppColors.textMuted,
                ),
              )
            else
              for (final bid in _bids) ...[
                _BidRow(
                  bid: bid,
                  busy: _busyBidId == bid.bidId,
                  enabled: _busyBidId == null,
                  onAccept: () => _accept(bid),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
              ],
            if (widget.onEditShift != null) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
              TextButton(
                onPressed: _busyBidId != null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        widget.onEditShift!();
                      },
                child: const Text('Edit shift'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BidRow extends StatelessWidget {
  final ShiftBid bid;
  final bool busy;
  final bool enabled;
  final VoidCallback onAccept;

  const _BidRow({
    required this.bid,
    required this.busy,
    required this.enabled,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bid.staffName,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textHeading,
                    ),
                  ),
                  if (bid.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      bid.note.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: enabled ? onAccept : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryTeal,
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }
}
