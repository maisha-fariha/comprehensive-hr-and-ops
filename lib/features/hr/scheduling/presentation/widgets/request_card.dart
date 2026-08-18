import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/shift_request.dart';
import '../../scheduling_constants.dart';

/// Visual status for the request card chrome (domain enum has no `declined`).
enum RequestCardStatus { pending, approved, declined }

class _AvatarPalette {
  final Color color;
  final Color background;

  const _AvatarPalette(this.color, this.background);
}

const Map<String, _AvatarPalette> _avatarByInitials = {
  'SJ': _AvatarPalette(Color(0xFF2A5DA6), Color(0xFFEAF0F9)),
  'NP': _AvatarPalette(Color(0xFF2E8C58), Color(0xFFEAF6F0)),
  'JL': _AvatarPalette(Color(0xFF6A4BC7), Color(0xFFF0ECFB)),
  'CB': _AvatarPalette(Color(0xFFB4791C), Color(0xFFFCF5ED)),
};

const List<_AvatarPalette> _fallbackAvatars = [
  _AvatarPalette(Color(0xFF2A5DA6), Color(0xFFEAF0F9)),
  _AvatarPalette(Color(0xFF2E8C58), Color(0xFFEAF6F0)),
  _AvatarPalette(Color(0xFF6A4BC7), Color(0xFFF0ECFB)),
  _AvatarPalette(Color(0xFFB4791C), Color(0xFFFCF5ED)),
];

_AvatarPalette _paletteFor(String initials) {
  final key = initials.toUpperCase();
  return _avatarByInitials[key] ??
      _fallbackAvatars[key.hashCode.abs() % _fallbackAvatars.length];
}

/// A single shift-swap request card on the Requests tab.
class RequestCard extends StatelessWidget {
  final ShiftRequest request;
  final RequestCardStatus? visualStatus;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const RequestCard({
    super.key,
    required this.request,
    this.visualStatus,
    this.onApprove,
    this.onDecline,
  });

  RequestCardStatus get _status {
    if (visualStatus != null) return visualStatus!;
    return switch (request.status) {
      RequestStatus.pending => RequestCardStatus.pending,
      RequestStatus.approved => RequestCardStatus.approved,
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final isPending = status == RequestCardStatus.pending;
    final palette = _paletteFor(request.staffInitials);
    final avatarSize = ResponsiveHelper.getResponsiveSize(
      context,
      SchedulingDimens.requestAvatarSize,
    );
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final statusStyle = switch (status) {
      RequestCardStatus.pending => (
          label: 'Pending',
          color: const Color(0xFFB4791C),
          background: const Color(0xFFFCF5ED),
        ),
      RequestCardStatus.approved => (
          label: 'Approved',
          color: const Color(0xFF2E8C58),
          background: const Color(0xFFEAF6F0),
        ),
      RequestCardStatus.declined => (
          label: 'Declined',
          color: AppColors.textSecondary,
          background: const Color(0xFFF1F5F9),
        ),
    };

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 10)),
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  request.staffInitials,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: palette.color,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
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
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              color: AppColors.textHeading,
                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                        _Pill(
                          label: 'Swap',
                          color: const Color(0xFF2A5DA6),
                          background: const Color(0xFFEAF0F9),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                    Text(
                      request.timingLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              _Pill(
                label: statusStyle.label,
                color: statusStyle.color,
                background: statusStyle.background,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Container(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F9),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SwapDetail(
                    label: 'GIVING',
                    value: request.givingLabel,
                    alignEnd: false,
                  ),
                ),
                Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 8),
                  child: const AppSvgIcon(
                    'assets/icons/scheduling/swap.svg',
                    size: 18,
                    color: AppColors.secondaryTeal,
                  ),
                ),
                Expanded(
                  child: _SwapDetail(
                    label: 'RECEIVING',
                    value: request.receivingLabel,
                    alignEnd: true,
                  ),
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
                    asset: 'assets/icons/dashboard/cross_circle.svg',
                    isPrimary: false,
                    onTap: onDecline,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                Expanded(
                  child: _ActionButton(
                    label: 'Approve',
                    asset: 'assets/icons/dashboard/check_circle.svg',
                    isPrimary: true,
                    onTap: onApprove,
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

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _Pill({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

class _SwapDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _SwapDetail({
    required this.label,
    required this.value,
    required this.alignEnd,
  });

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
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            color: AppColors.textHeading,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String asset;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.asset,
    required this.isPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isPrimary ? Colors.white : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 11),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.secondaryTeal : AppColors.surfaceWhite,
          border: isPrimary ? null : Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 12),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(asset, size: 14, color: fg),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
