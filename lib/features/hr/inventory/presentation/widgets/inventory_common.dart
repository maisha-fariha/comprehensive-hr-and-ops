import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';

/// Opens a web-style modal as a tall bottom sheet.
Future<T?> showInventorySheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: builder,
    );

/// Header (icon, title, description), inline error, scrolling body and a
/// footer with an optional left note and the action buttons.
class InventorySheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? error;
  final List<Widget> children;
  final Widget? footerLeft;
  final List<Widget> actions;

  const InventorySheet({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.error,
    required this.children,
    this.footerLeft,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.quickActionCreateShiftBg,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, size: 18, color: AppColors.secondaryTeal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: handoverText(context, 16, weight: FontWeight.w600)),
                            if (description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                description!,
                                style: handoverText(context, 13, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (error != null) ...[
                          InventoryErrorBanner(message: error!),
                          const SizedBox(height: 14),
                        ],
                        ...children,
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (footerLeft != null)
                        SizedBox(width: double.infinity, child: footerLeft),
                      ...actions,
                    ],
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

class InventoryErrorBanner extends StatelessWidget {
  final String message;

  const InventoryErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('inventory-sheet-error'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.criticalBackgroundSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(message, style: handoverText(context, 13.5, color: AppColors.criticalRed)),
      );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed)),
            ],
          ),
          style: handoverText(context, 13, weight: FontWeight.w500),
        ),
      );
}

class _FieldNote extends StatelessWidget {
  final String text;
  final bool error;

  const _FieldNote(this.text, {this.error = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          text,
          style: handoverText(
            context,
            12,
            color: error ? AppColors.criticalRed : AppColors.textMuted,
          ),
        ),
      );
}

/// Labelled single-line input (text or number).
class InventoryField extends StatelessWidget {
  final String? label;
  final TextEditingController controller;
  final String? placeholder;
  final String? helper;
  final String? error;
  final bool number;
  final bool enabled;
  final bool required;
  final ValueChanged<String>? onChanged;

  const InventoryField({
    super.key,
    this.label,
    required this.controller,
    this.placeholder,
    this.helper,
    this.error,
    this.number = false,
    this.enabled = true,
    this.required = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: color),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) _FieldLabel(label!, required: required),
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: number
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
              : null,
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: placeholder,
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            filled: true,
            fillColor: enabled ? AppColors.surfaceWhite : AppColors.filterButtonBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: border(AppColors.searchBorder),
            enabledBorder: border(error != null ? AppColors.criticalRed : AppColors.searchBorder),
            disabledBorder: border(AppColors.searchBorder),
          ),
        ),
        if (error != null)
          _FieldNote(error!, error: true)
        else if (helper != null)
          _FieldNote(helper!),
      ],
    );
  }
}

/// Labelled select backed by the bottom-sheet picker.
class InventorySelect extends StatelessWidget {
  final String label;
  final List<(String, String)> options;
  final String? value;
  final String placeholder;
  final String? helper;
  final bool required;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const InventorySelect({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.placeholder,
    required this.onChanged,
    this.helper,
    this.required = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.where((o) => o.$1 == value).map((o) => o.$2).firstOrNull;
    return HandoverSelect(
      label: label,
      required: required,
      value: selected,
      placeholder: placeholder,
      helper: helper,
      onTap: !enabled
          ? null
          : () async {
              final picked = await pickHandoverOption(
                context,
                title: label,
                options: options,
                selected: value,
              );
              if (picked != null) onChanged(picked);
            },
    );
  }
}

/// Labelled `type="date"` input holding `YYYY-MM-DD` ('' when blank).
class InventoryDateField extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const InventoryDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Future<void> pick() async {
      final initial = DateTime.tryParse(value) ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked == null) return;
      String two(int v) => v.toString().padLeft(2, '0');
      onChanged('${picked.year}-${two(picked.month)}-${two(picked.day)}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label),
        Opacity(
          opacity: enabled ? 1 : 0.6,
          child: InkWell(
            onTap: enabled ? pick : null,
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
                      value.isEmpty ? 'dd/mm/yyyy' : value,
                      style: handoverText(
                        context,
                        13.5,
                        color: value.isEmpty ? AppColors.textMuted : AppColors.textHeading,
                      ),
                    ),
                  ),
                  if (value.isNotEmpty && enabled)
                    InkWell(
                      onTap: () => onChanged(''),
                      child: const Icon(Icons.close_rounded, size: 17, color: AppColors.textSecondary),
                    )
                  else
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        if (helper != null) _FieldNote(helper!),
      ],
    );
  }
}

class InventoryCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const InventoryCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: AppColors.secondaryTeal,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: handoverText(context, 13.5, weight: FontWeight.w500))),
          ],
        ),
      );
}

/// A titled group inside a sheet (`<section><h3>`).
class InventorySection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;

  const InventorySection({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(title, style: handoverText(context, 14, weight: FontWeight.w600)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );
}

/// Muted paragraph used for loading / empty copy.
class InventoryNote extends StatelessWidget {
  final String text;

  const InventoryNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: handoverText(context, 13, color: AppColors.textMuted));
}

/// A two-line list row with trailing widgets.
class InventoryRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> trailing;
  final Widget? leading;
  final Widget? below;

  const InventoryRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing = const [],
    this.leading,
    this.below,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: handoverText(context, 13.5, weight: FontWeight.w500)),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(subtitle!, style: handoverText(context, 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (trailing.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: trailing,
                  ),
                ],
              ],
            ),
            ?below,
          ],
        ),
      );
}

/// Centered icon + title + message card for empty and failed lists.
class InventoryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const InventoryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => HandoverPanel(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.filterButtonBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: handoverText(context, 15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: handoverText(context, 13.5, color: AppColors.textMuted),
            ),
          ],
        ),
      );
}

class InventorySkeleton extends StatelessWidget {
  final int count;
  final double height;

  const InventorySkeleton({super.key, this.count = 3, this.height = 110});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < count; i++)
            Container(
              height: height,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      );
}

/// Web `ConfirmDialog`. Resolves true when confirmed.
Future<bool> confirmInventoryAction(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  bool danger = true,
  String confirmKey = 'inventory-confirm',
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
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(dialogContext).pop(false)),
        Material(
          color: danger ? AppColors.criticalRed : AppColors.secondaryTeal,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            key: ValueKey(confirmKey),
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

/// Toolbar select ("All Residences", "All Categories") opening a picker.
class InventoryFilterButton extends StatelessWidget {
  final String title;
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;

  const InventoryFilterButton({
    super.key,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = options.where((o) => o.$1 == value).map((o) => o.$2).firstOrNull ??
        options.first.$2;
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () async {
          final picked = await pickHandoverOption(
            context,
            title: title,
            options: options,
            selected: value,
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: handoverText(context, 13.5, weight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header row for list pages: actions wrap under narrow widths.
class InventoryToolbar extends StatelessWidget {
  final List<Widget> children;

  const InventoryToolbar({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Wrap(spacing: 8, runSpacing: 8, children: children),
      );
}

/// Small bordered icon-only button (pencil, archive, trash).
class InventoryIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const InventoryIconButton({super.key, required this.icon, this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = HandoverButton(label: '', icon: icon, compact: true, onPressed: onPressed);
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
