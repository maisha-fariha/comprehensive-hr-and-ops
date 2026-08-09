import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';

/// Field label with optional red required asterisk.
class CreateIncidentFieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  static const Color _asterisk = Color(0xFFE5484D);

  const CreateIncidentFieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 8)),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textHeading,
                height: 1.2,
              ),
            ),
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: _asterisk,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Filled light-gray field shell matching the Create Incident reference.
class _FieldShell extends StatelessWidget {
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  static const Color _fill = Color(0xFFF4F7F9);

  const _FieldShell({required this.child, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
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
    color: isPlaceholder ? const Color(0xFF94A3B8) : AppColors.textHeading,
    height: 1.25,
  );
}

/// Editable filled text field (title / location).
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

/// Display-only dropdown-look field with trailing chevron.
class CreateIncidentDropdownField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  const CreateIncidentDropdownField({
    super.key,
    this.value,
    required this.placeholder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.isEmpty;
    return _FieldShell(
      onTap: onTap,
      trailing: const AppSvgIcon(
        AppAssets.chevronDown,
        size: 15,
        color: Color(0xFF94A3B8),
      ),
      child: Text(
        empty ? placeholder : value!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _fieldTextStyle(context, isPlaceholder: false),
      ),
    );
  }
}

/// Filled date field with trailing calendar icon.
class CreateIncidentDateField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const CreateIncidentDateField({
    super.key,
    required this.controller,
    this.hint = 'MM/DD/YYYY',
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      trailing: const AppSvgIcon(
        AppAssets.navCalendar,
        size: 16,
        color: AppColors.textHeading,
      ),
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

/// Filled time field with trailing clock icon.
class CreateIncidentTimeField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const CreateIncidentTimeField({
    super.key,
    required this.controller,
    this.hint = 'HH:MM',
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      trailing: const AppSvgIcon(
        AppAssets.clock,
        size: 16,
        color: AppColors.textHeading,
      ),
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
