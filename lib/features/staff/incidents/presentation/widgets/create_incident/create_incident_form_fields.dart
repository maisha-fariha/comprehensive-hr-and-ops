import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';

/// Bold field label shown above every field in the Create Incident form.
class CreateIncidentFieldLabel extends StatelessWidget {
  final String text;

  const CreateIncidentFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 7)),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: AppColors.textHeading,
        ),
      ),
    );
  }
}

/// The shared white/outlined field "shell" (border, radius, padding) used
/// by every text/dropdown/date/time field on the Create Incident form,
/// with an optional trailing icon slot.
class _FieldShell extends StatelessWidget {
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _FieldShell({required this.child, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: child),
          if (trailing != null) ...[
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content);
  }
}

TextStyle _fieldTextStyle(BuildContext context, {required bool isPlaceholder}) {
  return TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w500,
    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
    color: isPlaceholder ? AppColors.textFaint : AppColors.textHeading,
  );
}

/// A plain editable outlined text field, e.g. the incident title / location.
class CreateIncidentTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const CreateIncidentTextField({super.key, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      child: TextField(
        controller: controller,
        style: _fieldTextStyle(context, isPlaceholder: false),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: _fieldTextStyle(context, isPlaceholder: true),
        ),
      ),
    );
  }
}

/// A display-only "dropdown-look" field with a chevron - this is a mock UI
/// with no backing dropdown menu logic, matching the current scope of the
/// feature (front-end only, no real form persistence yet).
class CreateIncidentDropdownField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  const CreateIncidentDropdownField({super.key, this.value, required this.placeholder, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      onTap: onTap,
      trailing: const AppSvgIcon(AppAssets.chevronDown, size: 15, color: AppColors.textFaint),
      child: Text(
        value ?? placeholder,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _fieldTextStyle(context, isPlaceholder: value == null),
      ),
    );
  }
}

/// An outlined date field with a trailing calendar icon (reuses the
/// existing `nav_calendar.svg` asset - a plain calendar outline that is an
/// exact visual match, unlike `calendar_check`/`calendar_plus` which both
/// bundle an extra symbol).
class CreateIncidentDateField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const CreateIncidentDateField({super.key, required this.controller, this.hint = 'MM/DD/YYYY'});

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      trailing: const AppSvgIcon(AppAssets.navCalendar, size: 16, color: AppColors.textFaint),
      child: TextField(
        controller: controller,
        style: _fieldTextStyle(context, isPlaceholder: false),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: _fieldTextStyle(context, isPlaceholder: true),
        ),
      ),
    );
  }
}

/// An outlined time field with a trailing clock icon (reuses the existing
/// `clock.svg` asset - an exact visual match).
class CreateIncidentTimeField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const CreateIncidentTimeField({super.key, required this.controller, this.hint = 'HH:MM'});

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      trailing: const AppSvgIcon(AppAssets.clock, size: 16, color: AppColors.textFaint),
      child: TextField(
        controller: controller,
        style: _fieldTextStyle(context, isPlaceholder: false),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: _fieldTextStyle(context, isPlaceholder: true),
        ),
      ),
    );
  }
}
