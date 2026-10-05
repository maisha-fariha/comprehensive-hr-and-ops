import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/residence_summary.dart';

Widget residenceFieldLabel(BuildContext context, String label, {bool required = false}) {
  return Padding(
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

Widget residenceFieldError(BuildContext context, String? error) {
  if (error == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(error, style: handoverText(context, 12.5, color: AppColors.criticalRed)),
  );
}

InputDecoration residenceInputDecoration(
  BuildContext context, {
  String? hint,
  bool error = false,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surfaceWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: border(AppColors.searchBorder),
    enabledBorder: border(error ? AppColors.criticalRed : AppColors.searchBorder),
    focusedBorder: border(error ? AppColors.criticalRed : AppColors.secondaryTeal),
  );
}

/// Labelled text input with the web helper / error lines.
class ResidenceTextInput extends StatelessWidget {
  final String field;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final String? helper;
  final String? error;
  final bool required;
  final bool numeric;
  final int maxLines;
  final TextInputType? keyboardType;

  const ResidenceTextInput({
    super.key,
    required this.field,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.placeholder,
    this.helper,
    this.error,
    this.required = false,
    this.numeric = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        residenceFieldLabel(context, label, required: required),
        TextField(
          key: ValueKey('residence-field-$field'),
          controller: controller,
          onChanged: onChanged,
          minLines: maxLines > 1 ? 3 : 1,
          maxLines: maxLines,
          keyboardType: keyboardType ??
              (numeric ? TextInputType.number : TextInputType.text),
          inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: handoverText(context, 13.5),
          decoration: residenceInputDecoration(
            context,
            hint: placeholder,
            error: error != null,
          ),
        ),
        if (helper != null && error == null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(helper!, style: handoverText(context, 12, color: AppColors.textMuted)),
          ),
        residenceFieldError(context, error),
      ],
    );
  }
}

/// Labelled single select that opens a bottom sheet (searchable when asked).
class ResidenceSelectInput extends StatelessWidget {
  final String field;
  final String label;
  final String? value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final String? error;
  final bool required;
  final bool searchable;

  const ResidenceSelectInput({
    super.key,
    required this.field,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder = 'Select',
    this.error,
    this.required = false,
    this.searchable = false,
  });

  @override
  Widget build(BuildContext context) {
    String? display;
    for (final (id, text) in options) {
      if (id == value) display = text;
    }
    if (display == null && value != null && value!.isNotEmpty) display = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        residenceFieldLabel(context, label, required: required),
        InkWell(
          key: ValueKey('residence-field-$field'),
          borderRadius: BorderRadius.circular(9),
          onTap: () async {
            final picked = await pickResidenceOptions(
              context,
              title: label,
              options: options,
              selected: {?value},
              searchable: searchable,
            );
            if (picked != null && picked.isNotEmpty) onChanged(picked.first);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: error != null ? AppColors.criticalRed : AppColors.searchBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display ?? placeholder,
                    style: handoverText(
                      context,
                      13.5,
                      color: display == null ? AppColors.textMuted : AppColors.textHeading,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        residenceFieldError(context, error),
      ],
    );
  }
}

/// Chip list with add / remove for the staff multi-selects.
class ResidenceStaffChips extends StatelessWidget {
  final String field;
  final String label;
  final List<String> value;
  final List<ResidenceStaffOption> options;
  final String placeholder;
  final ValueChanged<List<String>> onChanged;

  const ResidenceStaffChips({
    super.key,
    required this.field,
    required this.label,
    required this.value,
    required this.options,
    required this.placeholder,
    required this.onChanged,
  });

  String _label(String id) {
    for (final o in options) {
      if (o.id == id) return o.label;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        residenceFieldLabel(context, label),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final id in value)
                InputChip(
                  key: ValueKey('residence-chip-$field-$id'),
                  label: Text(_label(id), style: handoverText(context, 12.5, weight: FontWeight.w500)),
                  backgroundColor: AppColors.quickActionCreateShiftBg,
                  side: BorderSide.none,
                  deleteIconColor: AppColors.secondaryTeal,
                  onDeleted: () => onChanged([...value]..remove(id)),
                ),
              TextButton.icon(
                key: ValueKey('residence-field-$field'),
                onPressed: () async {
                  final picked = await pickResidenceOptions(
                    context,
                    title: label,
                    options: [for (final o in options) (o.id, o.label)],
                    selected: value.toSet(),
                    searchable: true,
                    multiple: true,
                  );
                  if (picked != null) onChanged(picked);
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.secondaryTeal),
                label: Text(
                  placeholder,
                  style: handoverText(context, 12.5, weight: FontWeight.w600, color: AppColors.secondaryTeal),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom-sheet picker; returns the chosen ids (null when dismissed).
Future<List<String>?> pickResidenceOptions(
  BuildContext context, {
  required String title,
  required List<(String, String)> options,
  Set<String> selected = const {},
  bool searchable = false,
  bool multiple = false,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _OptionSheet(
      title: title,
      options: options,
      selected: selected,
      searchable: searchable,
      multiple: multiple,
    ),
  );
}

class _OptionSheet extends StatefulWidget {
  final String title;
  final List<(String, String)> options;
  final Set<String> selected;
  final bool searchable;
  final bool multiple;

  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchable,
    required this.multiple,
  });

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  late final Set<String> _picked = {...widget.selected};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = widget.options
        .where((o) => q.isEmpty || o.$2.toLowerCase().contains(q))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title, style: handoverText(context, 16, weight: FontWeight.w700)),
                    ),
                    if (widget.multiple)
                      HandoverButton(
                        key: const ValueKey('residence-options-done'),
                        label: 'Done',
                        filled: true,
                        compact: true,
                        onPressed: () => Navigator.of(context).pop(
                          [
                            for (final (id, _) in widget.options)
                              if (_picked.contains(id)) id,
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.searchable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    key: const ValueKey('residence-options-search'),
                    onChanged: (v) => setState(() => _query = v),
                    style: handoverText(context, 13.5),
                    decoration: residenceInputDecoration(context, hint: 'Search staff…'),
                  ),
                ),
              Flexible(
                child: visible.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No results.',
                          textAlign: TextAlign.center,
                          style: handoverText(context, 13.5, color: AppColors.textMuted),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final (id, label) in visible)
                            ListTile(
                              title: Text(label, style: handoverText(context, 14)),
                              trailing: _picked.contains(id)
                                  ? const Icon(Icons.check_rounded, color: AppColors.secondaryTeal)
                                  : null,
                              onTap: () {
                                if (!widget.multiple) {
                                  Navigator.of(context).pop([id]);
                                  return;
                                }
                                setState(() {
                                  if (!_picked.remove(id)) _picked.add(id);
                                });
                              },
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Web `em` radio card (residence type / status choices).
class ResidenceChoiceCard extends StatelessWidget {
  final String label;
  final String? description;
  final IconData? icon;
  final Color tone;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const ResidenceChoiceCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tone,
    this.description,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF7FCFB) : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.secondaryTeal : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: compact
            ? Column(
                children: [
                  if (icon != null)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: tone),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: handoverText(
                      context,
                      13.5,
                      weight: FontWeight.w600,
                      color: selected ? AppColors.secondaryTeal : AppColors.textHeading,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 16, color: tone),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: handoverText(
                            context,
                            13.5,
                            weight: FontWeight.w600,
                            color: selected ? AppColors.secondaryTeal : AppColors.textHeading,
                          ),
                        ),
                        if (description != null)
                          Text(description!, style: handoverText(context, 11.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Web `ea` card: icon, title, description and its fields.
class ResidenceFormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  const ResidenceFormCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.quickActionCreateShiftBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: AppColors.secondaryTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: handoverText(context, 14.5, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(description, style: handoverText(context, 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          for (final child in children) ...[const SizedBox(height: 14), child],
        ],
      ),
    );
  }
}
