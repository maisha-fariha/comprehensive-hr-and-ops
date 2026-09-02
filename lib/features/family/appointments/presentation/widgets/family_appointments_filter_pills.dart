import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// "Date range" / "All types" filter pill row. Filters are applied
/// client-side from `GET /family/appointments`.
class FamilyAppointmentsFilterPills extends StatelessWidget {
  final String dateLabel;
  final String typeLabel;
  final VoidCallback? onDateTap;
  final VoidCallback? onTypeTap;

  const FamilyAppointmentsFilterPills({
    super.key,
    this.dateLabel = 'Date range',
    this.typeLabel = 'All types',
    this.onDateTap,
    this.onTypeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterPill(label: dateLabel, onTap: onDateTap),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: _FilterPill(label: typeLabel, onTap: onTypeTap),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  static const Color _labelColor = Color(0xFF16293F);
  static const Color _chevronColor = Color(0xFF64748B);
  static const Color _border = Color(0xFFE8ECF0);

  const _FilterPill({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 14),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: _labelColor,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            const AppSvgIcon(AppAssets.chevronDown, size: 14, color: _chevronColor),
          ],
        ),
      ),
    );
  }
}
