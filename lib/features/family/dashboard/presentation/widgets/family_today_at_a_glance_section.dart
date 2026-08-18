import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_glance_item.dart';

class _GlanceStyle {
  final String asset;
  final Color accent;
  final Color background;

  const _GlanceStyle({
    required this.asset,
    required this.accent,
    required this.background,
  });
}

const Map<String, _GlanceStyle> _glanceStyles = {
  'wellbeing': _GlanceStyle(
    asset: 'assets/icons/family_core/emoji.svg',
    accent: Color(0xFF2E8C58),
    background: Color(0xFFEAF6F0),
  ),
  'meals': _GlanceStyle(
    asset: 'assets/icons/family_core/meals.svg',
    accent: Color(0xFF0E7C7B),
    background: Color(0xFFE6F5F2),
  ),
  'activities': _GlanceStyle(
    asset: 'assets/icons/family_core/activities.svg',
    accent: Color(0xFF6A4BC7),
    background: Color(0xFFF0ECFB),
  ),
  'sleep': _GlanceStyle(
    asset: 'assets/icons/family_core/sleep.svg',
    accent: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
  ),
};

const _GlanceStyle _fallbackStyle = _GlanceStyle(
  asset: 'assets/icons/family_core/emoji.svg',
  accent: Color(0xFF0E7C7B),
  background: Color(0xFFE6F5F2),
);

/// "Today at a Glance" heading + 2×2 metric cards.
class FamilyTodayAtAGlanceSection extends StatelessWidget {
  final List<FamilyGlanceItem> items;
  final ValueChanged<FamilyGlanceItem>? onItemTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _labelColor = Color(0xFF707E8C);
  static const Color _border = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const FamilyTodayAtAGlanceSection({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    final rowGap = ResponsiveHelper.getResponsiveHeight(context, 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today at a Glance',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            color: _titleColor,
            height: 1.2,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        ..._buildRows(context, gap, rowGap),
      ],
    );
  }

  List<Widget> _buildRows(BuildContext context, double gap, double rowGap) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      if (i > 0) {
        rows.add(SizedBox(height: rowGap));
      }
      final left = items[i];
      final hasRight = i + 1 < items.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _GlanceCard(item: left, onTap: onItemTap)),
              SizedBox(width: gap),
              Expanded(
                child: hasRight
                    ? _GlanceCard(item: items[i + 1], onTap: onItemTap)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}

class _GlanceCard extends StatelessWidget {
  final FamilyGlanceItem item;
  final ValueChanged<FamilyGlanceItem>? onTap;

  const _GlanceCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _glanceStyles[item.id] ?? _fallbackStyle;
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: FamilyTodayAtAGlanceSection._border),
          boxShadow: [
            BoxShadow(
              color: FamilyTodayAtAGlanceSection._shadow.withValues(alpha: 0.04),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
            ),
            BoxShadow(
              color: FamilyTodayAtAGlanceSection._shadow.withValues(alpha: 0.05),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 14),
                ),
              ),
              alignment: Alignment.center,
              child: AppSvgIcon(style.asset, size: 22, color: style.accent),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: FamilyTodayAtAGlanceSection._labelColor,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                      color: FamilyTodayAtAGlanceSection._titleColor,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
