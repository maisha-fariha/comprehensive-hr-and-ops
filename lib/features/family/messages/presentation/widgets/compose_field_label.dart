import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Bold field label used above compose fields ("To", "Message", "Attachments"),
/// with an optional muted suffix (e.g. "(Optional)").
class ComposeFieldLabel extends StatelessWidget {
  final String text;
  final String? suffix;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _suffixColor = Color(0xFF8E9BAE);

  const ComposeFieldLabel(this.text, {super.key, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveHeight(context, 8),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: _titleColor,
            height: 1.2,
          ),
          children: [
            TextSpan(text: text),
            if (suffix != null)
              TextSpan(
                text: ' $suffix',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: _suffixColor,
                ),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
