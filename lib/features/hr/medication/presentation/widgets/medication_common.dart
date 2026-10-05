import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../medication_labels.dart';

/// The web `Badge` in one of its variants.
class MarPill extends StatelessWidget {
  final String label;
  final MarTone tone;
  final bool rounded;

  const MarPill({super.key, required this.label, required this.tone, this.rounded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(rounded ? 6 : 999),
      ),
      child: Text(
        label,
        style: handoverText(context, 11.5, weight: FontWeight.w700, color: tone.foreground),
      ),
    );
  }
}

/// Small coloured dot used beside a medicine name.
class MarDot extends StatelessWidget {
  final Color color;

  const MarDot(this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Round initials avatar.
class MarAvatar extends StatelessWidget {
  final String initials;
  final Color color;

  const MarAvatar({super.key, required this.initials, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(
          initials,
          style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.surfaceWhite),
        ),
      );
}

/// Bottom-sheet header: icon, title, description, optional badge, close.
class MarSheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? badge;

  const MarSheetHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: AppColors.surfaceWhite),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: handoverText(context, 16, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description, style: handoverText(context, 13, color: AppColors.textMuted)),
                if (badge != null) ...[const SizedBox(height: 8), badge!],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Sticky footer holding the modal buttons.
class MarSheetFooter extends StatelessWidget {
  final Widget? leading;
  final List<Widget> children;

  const MarSheetFooter({super.key, this.leading, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(height: 8)],
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
        ],
      ),
    );
  }
}

/// Red inline alert (`role="alert"` on the web).
class MarErrorBox extends StatelessWidget {
  final String message;

  const MarErrorBox(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.criticalBackgroundSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: handoverText(context, 13.5, color: AppColors.criticalRed)),
    );
  }
}

/// Title + description that opens each form step.
class MarStepTitle extends StatelessWidget {
  final String title;
  final String description;

  const MarStepTitle({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: handoverText(context, 16, weight: FontWeight.w700, color: AppColors.primaryNavy)),
          const SizedBox(height: 2),
          Text(description, style: handoverText(context, 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Field label with the red required star.
class MarLabel extends StatelessWidget {
  final String text;
  final bool required;

  const MarLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              const TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed)),
          ],
        ),
        style: handoverText(context, 13, weight: FontWeight.w500),
      ),
    );
  }
}

/// Single-line labelled input.
class MarTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? helper;
  final String? error;
  final bool required;
  final bool numeric;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const MarTextField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.helper,
    this.error,
    this.required = false,
    this.numeric = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: c),
        );
    final edge = error != null ? AppColors.criticalRed : AppColors.searchBorder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) MarLabel(label, required: required),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: numeric ? TextInputType.number : null,
          inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: placeholder,
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: border(edge),
            enabledBorder: border(edge),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(error!, style: handoverText(context, 12, color: AppColors.criticalRed)),
        ] else if (helper != null) ...[
          const SizedBox(height: 5),
          Text(helper!, style: handoverText(context, 12, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

/// Labelled select that opens a bottom-sheet list of [options].
class MarSelectField extends StatelessWidget {
  final String label;
  final String value;
  final List<MarChoice> options;
  final String placeholder;
  final String? helper;
  final String? error;
  final bool required;
  final bool enabled;
  final bool allowClear;
  final ValueChanged<String> onChanged;

  const MarSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.placeholder,
    required this.onChanged,
    this.helper,
    this.error,
    this.required = false,
    this.enabled = true,
    this.allowClear = false,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.where((o) => o.$1 == value).map((o) => o.$2).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HandoverSelect(
          label: label,
          required: required,
          value: selected,
          placeholder: placeholder,
          onTap: enabled
              ? () async {
                  final picked = await pickHandoverOption(
                    context,
                    title: label.isEmpty ? placeholder : label,
                    options: [
                      if (allowClear) ('', placeholder),
                      ...options,
                    ],
                    selected: value,
                  );
                  if (picked != null) onChanged(picked);
                }
              : null,
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(error!, style: handoverText(context, 12, color: AppColors.criticalRed)),
        ] else if (helper != null) ...[
          const SizedBox(height: 5),
          Text(helper!, style: handoverText(context, 12, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

/// A danger confirm dialog in the web `ConfirmDialog` shape.
Future<bool> showMarConfirm(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      title: Text(title, style: handoverText(dialogContext, 17, weight: FontWeight.w700)),
      content: Text(
        description,
        style: handoverText(dialogContext, 13.5, color: AppColors.textSecondary),
      ),
      actions: [
        HandoverButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        Material(
          color: AppColors.criticalRed,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            key: const ValueKey('mar-confirm'),
            borderRadius: BorderRadius.circular(9),
            onTap: () => Navigator.of(dialogContext).pop(true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                confirmLabel,
                style: handoverText(
                  dialogContext,
                  13.5,
                  weight: FontWeight.w600,
                  color: AppColors.surfaceWhite,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Centered muted line used for loading and empty states.
class MarEmpty extends StatelessWidget {
  final String text;

  const MarEmpty(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: handoverText(context, 13.5, color: AppColors.textMuted),
        ),
      );
}
