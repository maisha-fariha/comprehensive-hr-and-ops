import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Bold field label with an optional red required-asterisk, shared by every
/// field in the "Create Incident" wizard.
class WizardFieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const WizardFieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 7)),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textHeading,
          ),
          children: [
            TextSpan(text: text),
            if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed)),
          ],
        ),
      ),
    );
  }
}

/// The shared white/outlined field "shell" (border, radius, padding) used
/// by every text/dropdown/search/date/time field in the wizard, with an
/// optional trailing icon slot.
class _WizardFieldShell extends StatelessWidget {
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double verticalPadding;

  const _WizardFieldShell({
    required this.child,
    this.trailing,
    this.onTap,
    this.verticalPadding = 14,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: verticalPadding),
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

/// A plain editable outlined text field (single or multi-line).
class WizardTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const WizardTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return _WizardFieldShell(
      verticalPadding: maxLines > 1 ? 12 : 14,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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

/// An outlined text field with a trailing search icon, e.g.
/// "Search client..." / "Search staff...".
class WizardSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  const WizardSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return _WizardFieldShell(
      trailing: const AppSvgIcon(AppAssets.search, size: 17, color: AppColors.textFaint),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
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
/// wizard (front-end only, no real form persistence yet).
class WizardDropdownField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  const WizardDropdownField({super.key, this.value, required this.placeholder, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _WizardFieldShell(
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

/// An outlined date field, e.g. "MM/DD/YYYY", with a trailing calendar icon.
///
/// Icon note: no existing SVG matches a plain calendar glyph
/// (`calendar_check.svg`/`calendar_plus.svg` both bundle an extra symbol),
/// so this uses Material `Icons.calendar_today_outlined` as a stand-in.
///
/// When [onTap] is provided, the field is read-only and both the field and
/// calendar icon open the picker.
class WizardDateField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onTap;

  const WizardDateField({
    super.key,
    required this.controller,
    this.hint = 'MM/DD/YYYY',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.calendar_today_outlined,
      size: ResponsiveHelper.getResponsiveSize(context, 16),
      color: AppColors.textFaint,
    );

    return _WizardFieldShell(
      trailing: onTap == null
          ? icon
          : GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(
                  ResponsiveHelper.getResponsiveSize(context, 2),
                ),
                child: icon,
              ),
            ),
      child: TextField(
        controller: controller,
        readOnly: onTap != null,
        onTap: onTap,
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

/// An outlined time field, e.g. "HH:MM", with a trailing clock icon (reuses
/// the existing `clock.svg` asset - an exact visual match).
///
/// When [onTap] is provided, the field is read-only and both the field and
/// clock icon open the picker.
class WizardTimeField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onTap;

  const WizardTimeField({
    super.key,
    required this.controller,
    this.hint = 'HH:MM',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const icon = AppSvgIcon(AppAssets.clock, size: 16, color: AppColors.textFaint);

    return _WizardFieldShell(
      trailing: onTap == null
          ? icon
          : GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(
                  ResponsiveHelper.getResponsiveSize(context, 2),
                ),
                child: icon,
              ),
            ),
      child: TextField(
        controller: controller,
        readOnly: onTap != null,
        onTap: onTap,
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
