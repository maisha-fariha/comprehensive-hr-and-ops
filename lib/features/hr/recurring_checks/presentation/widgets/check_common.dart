import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Single-line labelled field (text, number, date or time trigger).
class CheckInput extends StatelessWidget {
  final String? label;
  final TextEditingController controller;
  final String? placeholder;
  final String? helper;
  final bool required;
  final bool number;
  final ValueChanged<String>? onChanged;

  const CheckInput({
    super.key,
    required this.controller,
    this.label,
    this.placeholder,
    this.helper,
    this.required = false,
    this.number = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          CheckFieldLabel(label!, required: required),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true, signed: true)
              : TextInputType.text,
          inputFormatters: number
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
              : null,
          style: handoverText(context, 13.5),
          decoration: checkInputDecoration(context, placeholder),
        ),
        if (helper != null) ...[
          const SizedBox(height: 5),
          Text(helper!, style: handoverText(context, 12, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

InputDecoration checkInputDecoration(BuildContext context, String? placeholder) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: AppColors.searchBorder),
  );
  return InputDecoration(
    isDense: true,
    hintText: placeholder,
    hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surfaceWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: border,
    enabledBorder: border,
  );
}

class CheckFieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const CheckFieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          if (required)
            const TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed)),
        ],
      ),
      style: handoverText(context, 13, weight: FontWeight.w500),
    );
  }
}

/// Tap target showing a picked value (date / time), styled as a field.
class CheckPickerField extends StatelessWidget {
  final String? label;
  final String? value;
  final String placeholder;
  final String? helper;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const CheckPickerField({
    super.key,
    required this.value,
    required this.onTap,
    this.label,
    this.placeholder = '',
    this.helper,
    this.icon = Icons.calendar_today_outlined,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          CheckFieldLabel(label!),
          const SizedBox(height: 6),
        ],
        InkWell(
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
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
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
                if (!empty && onClear != null)
                  InkWell(
                    onTap: onClear,
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                  ),
              ],
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

/// The web bordered switch row ("Only mine", "Alert on an abnormal reading").
class CheckSwitchTile extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const CheckSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.activeColor = AppColors.secondaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.searchBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: handoverText(context, 13.5, weight: FontWeight.w600)),
                  if (description != null)
                    Text(
                      description!,
                      style: handoverText(context, 12, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: activeColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Web `aria-pressed` toggle chip (weekdays, notify roles).
class CheckToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CheckToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondaryTeal.withValues(alpha: 0.1)
              : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.secondaryTeal : AppColors.searchBorder,
          ),
        ),
        child: Text(
          label,
          style: handoverText(
            context,
            12.5,
            color: selected ? AppColors.secondaryTeal : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Titled group inside the schedule form ("The check", "How often").
class CheckSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const CheckSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: handoverText(context, 14.5, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          children[i],
        ],
      ],
    );
  }
}

/// Coloured message box (form error, warnings, "on their behalf").
class CheckNotice extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool bordered;

  const CheckNotice({
    super.key,
    required this.child,
    this.color = AppColors.criticalRed,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: bordered ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: child,
    );
  }
}

/// Header, scrolling body and Cancel / primary footer of a check sheet.
class CheckSheetScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;
  final String primaryLabel;
  final Key primaryKey;
  final VoidCallback? onPrimary;

  const CheckSheetScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
    required this.primaryLabel,
    required this.primaryKey,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.activeBackground,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: handoverText(context, 17, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: handoverText(context, 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    children[i],
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HandoverButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    HandoverButton(
                      key: primaryKey,
                      label: primaryLabel,
                      filled: true,
                      onPressed: onPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showCheckSheet<T>(BuildContext context, Widget Function(BuildContext) builder) =>
    showAppBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: builder,
    );
