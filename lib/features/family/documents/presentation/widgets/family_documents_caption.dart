import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';

/// Caption under the Documents title: shield-check icon + approval note.
class FamilyDocumentsCaption extends StatelessWidget {
  final String text;

  static const Color _textColor = Color(0xFF64748B);
  static const Color _iconColor = Color(0xFF0E7C7B);
  static const String _shieldIcon = 'assets/icons/family_more/shield.svg';

  const FamilyDocumentsCaption({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          top: 0,
          bottom: 14,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppSvgIcon(_shieldIcon, size: 14, color: _iconColor),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: _textColor,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
