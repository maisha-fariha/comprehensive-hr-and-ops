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
  final bool hasError;

  const _FieldShell({
    required this.child,
    this.trailing,
    this.onTap,
    this.hasError = false,
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
        border: Border.all(
          color: hasError ? AppColors.criticalRed : AppColors.searchBorder,
        ),
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
  final bool hasError;

  const CreateShiftDropdownField({
    super.key,
    this.value,
    required this.placeholder,
    this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      onTap: onTap,
      hasError: hasError,
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
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;
  final bool hasError;

  const CreateShiftDateField({
    super.key,
    required this.value,
    this.placeholder = 'Select date',
    this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      onTap: onTap,
      hasError: hasError,
      trailing: Icon(
        Icons.calendar_today_outlined,
        size: ResponsiveHelper.getResponsiveSize(context, 16),
        color: AppColors.textFaint,
      ),
      child: Text(
        value ?? placeholder,
        style: _fieldStyle(context, placeholder: value == null),
      ),
    );
  }
}

class CreateShiftTimeField extends StatelessWidget {
  final String? value;
  final VoidCallback? onTap;
  final bool hasError;

  const CreateShiftTimeField({
    super.key,
    required this.value,
    this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      onTap: onTap,
      hasError: hasError,
      trailing: const AppSvgIcon(
        AppAssets.clock,
        size: 16,
        color: AppColors.textFaint,
      ),
      child: Text(
        value ?? '--:--',
        style: _fieldStyle(context, placeholder: value == null),
      ),
    );
  }
}

class CreateShiftTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool hasError;

  const CreateShiftTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      hasError: hasError,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: textInputAction,
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

class CreateShiftErrorText extends StatelessWidget {
  final String? text;

  const CreateShiftErrorText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final message = text;
    if (message == null || message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(
        top: ResponsiveHelper.getResponsiveHeight(context, 6),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
          color: AppColors.criticalRed,
          height: 1.35,
        ),
      ),
    );
  }
}

/// Section title + description shown at the top of every wizard step.
class CreateShiftSectionHeader extends StatelessWidget {
  final String title;
  final String description;

  const CreateShiftSectionHeader({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveHeight(context, 20),
      ),
      child: Column(
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
            description,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered label + description + switch row used by the toggle steps.
class CreateShiftSwitchCard extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CreateShiftSwitchCard({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        side: const BorderSide(color: AppColors.searchBorder),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          14.5,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.secondaryTeal,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.cardBorder,
                trackOutlineColor:
                    const WidgetStatePropertyAll(Colors.transparent),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muted rounded note box (recurring summary, tenant settings hint).
class CreateShiftNoteBox extends StatelessWidget {
  final String text;

  const CreateShiftNoteBox(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: AppColors.textSecondary,
          height: 1.4,
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
