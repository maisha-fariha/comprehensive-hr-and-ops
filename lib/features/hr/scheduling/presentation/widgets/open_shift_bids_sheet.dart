import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/entities/calendar_shift.dart';
import '../../domain/entities/shift_bid.dart';
import '../controllers/scheduling_controller.dart';

/// Web Open shift dialog (`Q`): bids empty/list + Accept/Reject + footer actions.
Future<void> showOpenShiftBidsSheet({
  required BuildContext context,
  required SchedulingController controller,
  required CalendarShift shift,
  VoidCallback? onEditShift,
  Future<void> Function()? onCancelShift,
  Future<void> Function()? onDeleteShift,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _OpenShiftSheet(
      controller: controller,
      shift: shift,
      onEditShift: onEditShift,
      onCancelShift: onCancelShift,
      onDeleteShift: onDeleteShift,
    ),
  );
}

class _OpenShiftSheet extends StatefulWidget {
  final SchedulingController controller;
  final CalendarShift shift;
  final VoidCallback? onEditShift;
  final Future<void> Function()? onCancelShift;
  final Future<void> Function()? onDeleteShift;

  const _OpenShiftSheet({
    required this.controller,
    required this.shift,
    this.onEditShift,
    this.onCancelShift,
    this.onDeleteShift,
  });

  @override
  State<_OpenShiftSheet> createState() => _OpenShiftSheetState();
}

class _OpenShiftSheetState extends State<_OpenShiftSheet> {
  late List<ShiftBid> _bids;
  String? _busyBidId;
  bool _busy = false;

  bool get _canWrite => widget.controller.canWrite;

  @override
  void initState() {
    super.initState();
    _bids = List<ShiftBid>.from(widget.shift.pendingBids);
  }

  Future<void> _accept(ShiftBid bid) async {
    if (_busyBidId != null || !_canWrite) return;
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

  Future<void> _reject(ShiftBid bid) async {
    if (_busyBidId != null || !_canWrite) return;
    setState(() => _busyBidId = bid.bidId);
    final ok = await widget.controller.rejectShiftBid(
      shiftId: widget.shift.id,
      bidId: bid.bidId,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _bids.removeWhere((b) => b.bidId == bid.bidId);
        _busyBidId = null;
      });
      return;
    }
    setState(() => _busyBidId = null);
  }

  Future<void> _runFooter(Future<void> Function()? action) async {
    if (action == null || _busy || _busyBidId != null) return;
    setState(() => _busy = true);
    Navigator.of(context).pop();
    await action();
  }

  String get _subtitle {
    final shift = widget.shift;
    final duration = WebFormat.durationHours(shift.startsAt, shift.endsAt);
    final when = [
      if (shift.startsAt != null) WebFormat.date(shift.startsAt),
      if (shift.startsAt != null && shift.endsAt != null)
        '${WebFormat.time(shift.startsAt)}–${WebFormat.time(shift.endsAt)}'
            '${duration == null ? '' : ' ($duration)'}',
      if (shift.timeRange.isNotEmpty &&
          (shift.startsAt == null || shift.endsAt == null))
        shift.timeRange,
    ].where((s) => s.isNotEmpty).join(' · ');
    final residence = (shift.residenceName ?? '').trim();
    return [when, if (residence.isNotEmpty) residence].join(' · ');
  }

  int? get _openCount {
    final open = widget.shift.total - widget.shift.filled;
    return open > 0 ? open : null;
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.shift.title ?? '').trim().isEmpty
        ? 'Open shift'
        : widget.shift.title!;
    final open = _openCount;
    final idle = _busyBidId == null && !_busy;

    return SafeArea(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 20,
          top: 8,
          bottom: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  17,
                                ),
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                          if (open != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.activeBackground,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$open open',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: AppColors.secondaryTeal,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12.5,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            Text(
              _bids.isEmpty
                  ? 'No bids yet'
                  : '${_bids.length} ${_bids.length == 1 ? 'staff has' : 'staff have'} bid for this shift',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textHeading,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            if (_bids.isEmpty)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                  color: AppColors.filterButtonBackground,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Nobody has put their name forward yet.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.36,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _bids.length,
                  separatorBuilder: (_, _) => SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 8),
                  ),
                  itemBuilder: (_, i) {
                    final bid = _bids[i];
                    return _BidRow(
                      bid: bid,
                      busy: _busyBidId == bid.bidId,
                      enabled: idle && _canWrite,
                      showActions: _canWrite,
                      onAccept: () => _accept(bid),
                      onReject: () => _reject(bid),
                    );
                  },
                ),
              ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_canWrite && widget.onEditShift != null)
                  _FooterButton(
                    label: 'Edit shift',
                    icon: Icons.edit_outlined,
                    color: AppColors.textHeading,
                    onPressed: idle
                        ? () {
                            Navigator.of(context).pop();
                            widget.onEditShift!();
                          }
                        : null,
                  ),
                if (_canWrite && widget.onCancelShift != null)
                  _FooterButton(
                    label: 'Cancel shift',
                    icon: Icons.block_rounded,
                    color: AppColors.urgentAmber,
                    onPressed: idle
                        ? () => _runFooter(widget.onCancelShift)
                        : null,
                  ),
                if (_canWrite && widget.onDeleteShift != null)
                  _FooterButton(
                    label: 'Delete shift',
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.criticalRed,
                    onPressed: idle
                        ? () => _runFooter(widget.onDeleteShift)
                        : null,
                  ),
                _FooterButton(
                  label: 'Close',
                  icon: null,
                  color: AppColors.textHeading,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
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
  final bool showActions;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BidRow({
    required this.bid,
    required this.busy,
    required this.enabled,
    required this.showActions,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
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
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showActions) ...[
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                TextButton(
                  onPressed: enabled ? onReject : null,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.criticalRed,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded, size: 16),
                      SizedBox(width: 2),
                      Text('Reject'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: enabled ? onAccept : null,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryTeal,
                    backgroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 2),
                      Text(
                        'Accept',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;

  const _FooterButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
