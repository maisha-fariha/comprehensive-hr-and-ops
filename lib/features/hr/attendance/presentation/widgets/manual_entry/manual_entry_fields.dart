import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';

/// Bold label with optional red required asterisk.
class ManualEntryFieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const ManualEntryFieldLabel(
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
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _FieldShell({
    required this.child,
    this.leading,
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
          if (leading != null) ...[
            leading!,
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          ],
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

class ManualEntryDropdownField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;
  final bool enabled;

  const ManualEntryDropdownField({
    super.key,
    this.value,
    required this.placeholder,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: _FieldShell(
        onTap: enabled ? onTap : null,
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
      ),
    );
  }
}

class ManualEntrySearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const ManualEntrySearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      leading: const AppSvgIcon(
        AppAssets.search,
        size: 16,
        color: AppColors.textFaint,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
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

class ManualEntryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const ManualEntryTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      child: TextField(
        controller: controller,
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

class ManualEntryDateTimeField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;
  final IconData icon;

  const ManualEntryDateTimeField({
    super.key,
    this.value,
    required this.placeholder,
    this.onTap,
    this.icon = Icons.calendar_today_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      onTap: onTap,
      trailing: Icon(
        icon,
        size: ResponsiveHelper.getResponsiveSize(context, 16),
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

class ManualEntryHelperText extends StatelessWidget {
  final String text;

  const ManualEntryHelperText(this.text, {super.key});

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

class ManualEntrySectionIntro extends StatelessWidget {
  final String title;
  final String subtitle;

  const ManualEntrySectionIntro({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
