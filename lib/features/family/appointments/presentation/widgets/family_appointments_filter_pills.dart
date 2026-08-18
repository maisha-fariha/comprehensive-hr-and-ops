import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Display-only "Date range" / "All types" filter pill row.
class FamilyAppointmentsFilterPills extends StatelessWidget {
  const FamilyAppointmentsFilterPills({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _FilterPill(label: 'Date range')),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        const Expanded(child: _FilterPill(label: 'All types')),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;

  static const Color _labelColor = Color(0xFF16293F);
  static const Color _chevronColor = Color(0xFF64748B);
  static const Color _border = Color(0xFFE8ECF0);

  const _FilterPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
