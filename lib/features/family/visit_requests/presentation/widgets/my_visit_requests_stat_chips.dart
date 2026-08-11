import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Row of 3 equal-width stat chips on the "My Requests" tab.
class MyVisitRequestsStatChips extends StatelessWidget {
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  static const Color _pending = Color(0xFFD98324);
  static const Color _approved = Color(0xFF2E8C58);
  static const Color _rejected = Color(0xFFD64545);
  static const Color _label = Color(0xFF8E9BAE);
  static const Color _border = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const MyVisitRequestsStatChips({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10));

    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: pendingCount,
            label: 'Pending',
            color: _pending,
          ),
        ),
        gap,
        Expanded(
          child: _StatChip(
            value: approvedCount,
            label: 'Approved',
            color: _approved,
          ),
        ),
        gap,
        Expanded(
          child: _StatChip(
            value: rejectedCount,
            label: 'Rejected',
            color: _rejected,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: MyVisitRequestsStatChips._border),
        boxShadow: [
          BoxShadow(
            color: MyVisitRequestsStatChips._shadow.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
          ),
          BoxShadow(
            color: MyVisitRequestsStatChips._shadow.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
              color: color,
              height: 1.1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: MyVisitRequestsStatChips._label,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
