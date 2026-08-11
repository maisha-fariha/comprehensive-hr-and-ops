import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Outlined "Search people or groups" field beneath the Messages title.
class FamilyMessagesSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  static const Color _fill = Color(0xFFF7F9FB);
  static const Color _border = Color(0xFFE2E8EE);
  static const Color _hint = Color(0xFF9AA8B8);
  static const Color _text = Color(0xFF1A2B48);

  const FamilyMessagesSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14),
      decoration: BoxDecoration(
        color: _fill,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
      ),
      child: Row(
        children: [
          const AppSvgIcon(AppAssets.search, size: 18, color: _hint),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: _text,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: ResponsiveHelper.getResponsivePadding(
                  context,
                  vertical: 14,
                ),
                hintText: 'Search people or groups',
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: _hint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
