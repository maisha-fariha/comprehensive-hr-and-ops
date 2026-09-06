import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';

/// Bold label with optional red required asterisk — matches the
/// "Add New Shift" reference form.
class CreateShiftFieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const CreateShiftFieldLabel(
    this.text, {
    super.key,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveHeight(context, 7),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textHeading,
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.criticalRed),
              ),
          ],
        ),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _FieldShell({
    required this.child,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 13,
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
          Expanded(child: child),
          if (trailing != null) ...[
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

TextStyle _fieldStyle(BuildContext context, {required bool placeholder}) {
  return TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w500,
    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
    color: placeholder ? AppColors.textFaint : AppColors.textHeading,
  );
}

class CreateShiftDropdownField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  const CreateShiftDropdownField({
    super.key,
    this.value,
    required this.placeholder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      onTap: onTap,
      trailing: const AppSvgIcon(
        AppAssets.chevronDown,
        size: 14,
        color: AppColors.textFaint,
      ),
      child: Text(
        value ?? placeholder,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _fieldStyle(context, placeholder: value == null),
      ),
    );
  }
}

class CreateShiftDateField extends StatelessWidget {
  final String value;
  final VoidCallback? onTap;

  const CreateShiftDateField({
    super.key,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      onTap: onTap,
      trailing: Icon(
        Icons.calendar_today_outlined,
        size: ResponsiveHelper.getResponsiveSize(context, 16),
        color: AppColors.textFaint,
      ),
      child: Text(value, style: _fieldStyle(context, placeholder: false)),
    );
  }
}

class CreateShiftTimeField extends StatelessWidget {
  final String value;
  final VoidCallback? onTap;

  const CreateShiftTimeField({
    super.key,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      onTap: onTap,
      trailing: const AppSvgIcon(
        AppAssets.clock,
        size: 16,
        color: AppColors.textFaint,
      ),
      child: Text(value, style: _fieldStyle(context, placeholder: false)),
    );
  }
}

class CreateShiftTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  const CreateShiftTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: maxLines > 1 ? maxLines : null,
        style: _fieldStyle(context, placeholder: false),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: _fieldStyle(context, placeholder: true),
        ),
      ),
    );
  }
}

class CreateShiftHelperText extends StatelessWidget {
  final String text;

  const CreateShiftHelperText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: ResponsiveHelper.getResponsiveHeight(context, 6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
          color: AppColors.textMuted,
          height: 1.35,
        ),
      ),
    );
  }
}

/// Two-column row that stacks to a single column on narrow widths.
class CreateShiftFieldRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const CreateShiftFieldRow({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 16)),
        Expanded(child: right),
      ],
    );
  }
}
