import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

TextStyle handoverText(
  BuildContext context,
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.textHeading,
  TextDecoration? decoration,
}) =>
    TextStyle(
      fontFamily: 'Outfit',
      fontWeight: weight,
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, size),
      color: color,
      decoration: decoration,
    );

/// The web `admin` (filled) and `admin-outline` buttons.
class HandoverButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final IconData? icon;
  final Color? foreground;
  final bool compact;

  const HandoverButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.icon,
    this.foreground,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = foreground ??
        (filled ? AppColors.surfaceWhite : AppColors.textHeading);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 9);
    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: Material(
        color: filled ? AppColors.secondaryTeal : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: label.isEmpty ? 9 : (compact ? 10 : 14),
              vertical: compact ? 7 : 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: filled ? null : Border.all(color: AppColors.searchBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 15), color: color),
                if (icon != null && label.isNotEmpty) const SizedBox(width: 6),
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: handoverText(
                      context,
                      compact ? 12.5 : 13.5,
                      weight: FontWeight.w600,
                      color: color,
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

/// White rounded card with the web border.
class HandoverPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color borderColor;

  const HandoverPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderColor = AppColors.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius:
            BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

/// Labelled multi-line text field used in the handover forms.
class HandoverTextArea extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? helper;
  final bool required;
  final int minLines;
  final ValueChanged<String>? onChanged;

  const HandoverTextArea({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.helper,
    this.required = false,
    this.minLines = 2,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) ...[
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.criticalRed),
                  ),
              ],
            ),
            style: handoverText(context, 13, weight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines + 4,
          onChanged: onChanged,
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: placeholder,
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 5),
          Text(helper!, style: handoverText(context, 12, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

/// Labelled select that opens a bottom-sheet list.
class HandoverSelect extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final String? helper;
  final bool required;
  final VoidCallback? onTap;

  const HandoverSelect({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    this.helper,
    this.required = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) ...[
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.criticalRed),
                  ),
              ],
            ),
            style: handoverText(context, 13, weight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
        ],
        Opacity(
          opacity: onTap == null ? 0.6 : 1,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.searchBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      empty ? placeholder : value!,
                      style: handoverText(
                        context,
                        13.5,
                        color: empty ? AppColors.textMuted : AppColors.textHeading,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 5),
          Text(helper!, style: handoverText(context, 12, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

/// Picks one of [options] (id, label) from a bottom sheet.
Future<String?> pickHandoverOption(
  BuildContext context, {
  required String title,
  required List<(String, String)> options,
  String? selected,
}) {
  return showAppBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                title,
                style: handoverText(sheetContext, 16, weight: FontWeight.w700),
              ),
            ),
            for (final (id, label) in options)
              ListTile(
                title: Text(label, style: handoverText(sheetContext, 14)),
                trailing: id == selected
                    ? const Icon(Icons.check_rounded, color: AppColors.secondaryTeal)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
