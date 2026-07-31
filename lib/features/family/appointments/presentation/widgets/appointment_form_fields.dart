import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../family_appointments_constants.dart';

/// Bold field label shown above every field on the Create Appointment form,
/// with an optional trailing muted suffix (e.g. "(Optional)").
class AppointmentFieldLabel extends StatelessWidget {
  final String text;
  final String? suffix;

  const AppointmentFieldLabel(this.text, {super.key, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 8)),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textHeading,
            ),
          ),
          if (suffix != null) ...[
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
            Text(
              suffix!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.textFaint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The shared white/outlined "pill" field shell (border, radius, padding)
/// used by every dropdown-look field on the Create Appointment form.
class AppointmentDropdownField extends StatelessWidget {
  final String value;
  final String? leadingIcon;

  const AppointmentDropdownField({super.key, required this.value, this.leadingIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            AppSvgIcon(leadingIcon!, size: 16, color: AppColors.secondaryTeal),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          ],
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: AppColors.textHeading,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          const AppSvgIcon(AppAssets.chevronDown, size: 15, color: AppColors.textFaint),
        ],
      ),
    );
  }
}

/// The multiline "Add a Note" textarea with a right-aligned character
/// counter (e.g. "63/250"), shown near the bottom of the Create Appointment
/// form.
class AppointmentNoteField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int length;

  const AppointmentNoteField({super.key, required this.controller, required this.hint, required this.length});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            maxLines: 3,
            minLines: 3,
            maxLength: FamilyAppointmentsConstants.noteMaxLength,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
              color: AppColors.textHeading,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              counterText: '',
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: AppColors.textFaint,
              ),
            ),
          ),
          Text(
            '$length/${FamilyAppointmentsConstants.noteMaxLength}',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

/// The mint-green "your request will be reviewed" info banner shown near
/// the bottom of the Create Appointment form.
///
/// Icon note: no shield-check SVG exists in `assets/icons/*` yet, so this
/// uses the Material `Icons.gpp_good_outlined` as a temporary stand-in.
class AppointmentInfoBanner extends StatelessWidget {
  final String message;

  const AppointmentInfoBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.activeBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gpp_good_outlined, size: ResponsiveHelper.getResponsiveSize(context, 18), color: AppColors.secondaryTealDark),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.secondaryTealDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
