import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/inventory_item.dart';
import '../inventory_labels.dart';

/// The five web KPI tiles, fed by `meta.summary` of the item list.
class InventoryKpiGrid extends StatelessWidget {
  final InventorySummary summary;
  final VoidCallback onShowLowStock;

  const InventoryKpiGrid({super.key, required this.summary, required this.onShowLowStock});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: a), SizedBox(width: gap), Expanded(child: b)],
          ),
        );
    final unpriced = summary.unpriced;
    return Column(
      children: [
        row(
          _Tile(
            key: const ValueKey('inventory-kpi-items'),
            icon: Icons.inventory_2_outlined,
            tone: AppColors.secondaryTeal,
            toneBackground: AppColors.quickActionCreateShiftBg,
            value: '${summary.items}',
            label: 'ITEMS',
            caption: const Text('On these shelves'),
          ),
          _Tile(
            key: const ValueKey('inventory-kpi-low'),
            icon: Icons.warning_amber_rounded,
            tone: AppColors.urgentAmber,
            toneBackground: AppColors.urgentBackground,
            value: '${summary.lowStock}',
            label: 'NEEDS ORDERING',
            caption: GestureDetector(
              key: const ValueKey('inventory-kpi-low-link'),
              onTap: onShowLowStock,
              child: const Text(
                'At or below its level',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ),
        SizedBox(height: gap),
        row(
          _Tile(
            key: const ValueKey('inventory-kpi-out'),
            icon: Icons.cancel_outlined,
            tone: AppColors.criticalRed,
            toneBackground: AppColors.criticalBackgroundSoft,
            value: '${summary.outOfStock}',
            label: 'OUT OF STOCK',
            caption: const Text('Nothing left at all'),
          ),
          _Tile(
            key: const ValueKey('inventory-kpi-watched'),
            icon: Icons.visibility_outlined,
            tone: AppColors.nightPurple,
            toneBackground: AppColors.nightBackground,
            value: '${summary.watched}',
            label: 'WATCHED',
            caption: const Text('Have a reorder level set'),
          ),
        ),
        SizedBox(height: gap),
        _Tile(
          key: const ValueKey('inventory-kpi-value'),
          icon: Icons.account_balance_wallet_outlined,
          tone: AppColors.secondaryTeal,
          toneBackground: AppColors.quickActionCreateShiftBg,
          value: InventoryLabels.money(summary.value),
          label: 'STOCK VALUE',
          caption: Text(
            unpriced > 0
                ? '${InventoryLabels.plural(unpriced, 'item')} not costed yet'
                : 'At average cost',
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final Color toneBackground;
  final String value;
  final String label;
  final Widget caption;

  const _Tile({
    super.key,
    required this.icon,
    required this.tone,
    required this.toneBackground,
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle text(double size, FontWeight weight, Color color) => TextStyle(
          fontFamily: 'Outfit',
          fontWeight: weight,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, size),
          color: color,
        );
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 14)),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 34),
            height: ResponsiveHelper.getResponsiveSize(context, 34),
            decoration: BoxDecoration(
              color: toneBackground,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 17), color: tone),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(value, style: text(24, FontWeight.w700, AppColors.textHeading)),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(label, style: text(11, FontWeight.w600, AppColors.textSecondary).copyWith(letterSpacing: 0.4)),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
          DefaultTextStyle(style: text(12, FontWeight.w400, AppColors.textMuted), child: caption),
        ],
      ),
    );
  }
}
