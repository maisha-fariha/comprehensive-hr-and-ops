import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Full-width filled teal "Send Message" button pinned to the bottom of the
/// "New Message" compose screen, mirroring the styling of
/// `lib/features/staff/incidents/presentation/widgets/staff_primary_button.dart`.
///
/// Icon note: no matching SVG exists in `assets/icons/*` for a paper-plane/
/// send glyph, so this uses `Icons.send_rounded` as a temporary stand-in,
/// matching the same fallback already used by
/// `lib/features/staff/tasks_messages/presentation/widgets/message_input_bar.dart`.
class SendMessageButton extends StatelessWidget {
  final VoidCallback onTap;

  const SendMessageButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.secondaryTeal,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 16),
          ),
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/family_messages/send.svg',
                  width: ResponsiveHelper.getResponsiveSize(context, 19),
                  color: Colors.white,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Text(
                  'Send Message',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
