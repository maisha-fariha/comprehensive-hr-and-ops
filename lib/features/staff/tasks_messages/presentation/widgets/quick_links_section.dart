import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// "Quick Links" grid under the Tasks list: Profile / Training / Documents /
/// Notifications.
class QuickLinksSection extends StatelessWidget {
  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _iconBoxBg = Color(0xFFE6F5F2);
  static const Color _iconColor = Color(0xFF0E7C7B);

  static const List<_QuickLinkItem> _items = [
    _QuickLinkItem(
      label: 'Profile',
      asset: 'assets/icons/staff_tasks_messages/profile.svg',
    ),
    _QuickLinkItem(
      label: 'Training',
      asset: 'assets/icons/staff_tasks_messages/training.svg',
    ),
    _QuickLinkItem(
      label: 'Documents',
      asset: 'assets/icons/staff_tasks_messages/document.svg',
    ),
    _QuickLinkItem(
      label: 'Notifications',
      asset: 'assets/icons/staff_tasks_messages/notification.svg',
    ),
  ];

  const QuickLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: _titleColor,
            height: 1.2,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        Row(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(child: _QuickLinkCard(item: _items[i])),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuickLinkItem {
  final String label;
  final String asset;

  const _QuickLinkItem({required this.label, required this.asset});
}

class _QuickLinkCard extends StatelessWidget {
  final _QuickLinkItem item;

  const _QuickLinkCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 40);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 8,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowNavy.withValues(alpha: 0.04),
                offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 3)),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: QuickLinksSection._iconBoxBg,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: AppSvgIcon(
                  item.asset,
                  size: ResponsiveHelper.getResponsiveSize(context, 20),
                  color: QuickLinksSection._iconColor,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                  color: QuickLinksSection._titleColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
