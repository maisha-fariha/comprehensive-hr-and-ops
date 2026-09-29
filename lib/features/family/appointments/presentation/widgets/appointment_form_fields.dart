import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Bold field label shown above every field on the Request a visit form,
/// with an optional required asterisk.
class AppointmentFieldLabel extends StatelessWidget {
  final String text;
  final String? suffix;
  final bool required;

  const AppointmentFieldLabel(
    this.text, {
    super.key,
    this.suffix,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveHeight(context, 8),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textHeading,
            ),
          ),
          if (required)
            Text(
              ' *',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.criticalRed,
              ),
            ),
          if (suffix != null) ...[
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
            Text(
              suffix!,
              style: TextStyle(
                fontFamily: 'Manrope',
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

/// Soft pink validation banner matching the web "Request a visit" modal.
class AppointmentFormErrorBanner extends StatelessWidget {
  final String message;

  const AppointmentFormErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.criticalBackgroundSoft,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        border: Border.all(color: AppColors.criticalBackground),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: AppColors.criticalRed,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Outlined field shell used by dropdown-style picks on the request form.
class AppointmentDropdownField extends StatelessWidget {
  final String value;
  final bool isPlaceholder;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  const AppointmentDropdownField({
    super.key,
    required this.value,
    this.isPlaceholder = false,
    this.trailingIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border.all(color: AppColors.searchBorder),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight:
                      isPlaceholder ? FontWeight.w500 : FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: isPlaceholder
                      ? AppColors.textMuted
                      : AppColors.textHeading,
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Icon(
              trailingIcon ?? Icons.keyboard_arrow_down_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 20),
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single-line outlined text field (Where).
class AppointmentTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const AppointmentTextField({
    super.key,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
          color: AppColors.textHeading,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Multiline notes textarea.
class AppointmentNoteField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool showCounter;
  final int length;

  const AppointmentNoteField({
    super.key,
    required this.controller,
    required this.hint,
    this.showCounter = false,
    this.length = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: 4,
        minLines: 4,
        style: TextStyle(
          fontFamily: 'Manrope',
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
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
