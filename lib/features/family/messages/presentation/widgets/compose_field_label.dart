import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Bold field label used above every field on the "New Message" compose
/// screen ("To", "Message", "Attachments"), with an optional grey suffix
/// (e.g. "(Optional)").
class ComposeFieldLabel extends StatelessWidget {
  final String text;
  final String? suffix;

  const ComposeFieldLabel(this.text, {super.key, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 8)),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
            color: AppColors.textHeading,
          ),
          children: [
            TextSpan(text: text),
            if (suffix != null)
              TextSpan(
                text: ' $suffix',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  color: AppColors.textFaint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
