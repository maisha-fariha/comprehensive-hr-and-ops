import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../training_labels.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// The web Badge variants used across the training screens.
enum TrainingTone { success, warning, danger, info, neutral, cyan, purple }

extension TrainingToneColors on TrainingTone {
  Color get foreground => switch (this) {
        TrainingTone.success => AppColors.activeGreen,
        TrainingTone.warning => AppColors.urgentAmber,
        TrainingTone.danger => AppColors.criticalRed,
        TrainingTone.info => AppColors.infoBlue,
        TrainingTone.neutral => AppColors.textSecondary,
        TrainingTone.cyan => AppColors.secondaryTeal,
        TrainingTone.purple => const Color(0xFF7656D6),
      };

  Color get background => switch (this) {
        TrainingTone.success => AppColors.activeBackground,
        TrainingTone.warning => AppColors.urgentBackground,
        TrainingTone.danger => AppColors.criticalBackgroundSoft,
        TrainingTone.info => AppColors.infoBackground,
        TrainingTone.neutral => AppColors.filterButtonBackground,
        TrainingTone.cyan => AppColors.quickActionCreateShiftBg,
        TrainingTone.purple => const Color(0xFFF1EAFE),
      };
}

class TrainingPill extends StatelessWidget {
  final String label;
  final TrainingTone tone;
  final bool dot;
  final IconData? icon;

  const TrainingPill({
    super.key,
    required this.label,
    required this.tone,
    this.dot = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tone.foreground, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone.foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: handoverText(context, 11, weight: FontWeight.w600, color: tone.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// A web StatCard: tinted icon, value, uppercase label and an optional hint.
class TrainingStatTile extends StatelessWidget {
  final IconData icon;
  final TrainingTone tone;
  final int value;
  final String label;
  final String? hint;

  const TrainingStatTile({
    super.key,
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 14)),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 34),
            height: ResponsiveHelper.getResponsiveSize(context, 34),
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 17), color: tone.foreground),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text('$value', style: handoverText(context, 24, weight: FontWeight.w700)),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            label.toUpperCase(),
            style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textSecondary)
                .copyWith(letterSpacing: 0.4),
          ),
          if (hint != null) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
            Text(hint!, style: handoverText(context, 12, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// Lays tiles out two per row, like the web grid at phone widths.
class TrainingTileGrid extends StatelessWidget {
  final List<Widget> tiles;

  const TrainingTileGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              SizedBox(width: gap),
              Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class TrainingEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;

  const TrainingEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          if (icon != null) ...[
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
          ],
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
}

class TrainingInlineError extends StatelessWidget {
  final String message;

  const TrainingInlineError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.criticalBackgroundSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: handoverText(context, 13.5, color: AppColors.criticalRed),
      ),
    );
  }
}

/// Label / value line inside a row card.
class TrainingField extends StatelessWidget {
  final String label;
  final Widget child;

  const TrainingField({super.key, required this.label, required this.child});

  TrainingField.text({
    super.key,
    required this.label,
    required String value,
    Color color = AppColors.textHeading,
  }) : child = Builder(
          builder: (context) => Text(value, style: handoverText(context, 13, color: color)),
        );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveHelper.getResponsiveWidth(context, 96),
            child: Text(
              label,
              style: handoverText(context, 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: child)),
        ],
      ),
    );
  }
}

/// Bottom-sheet frame for the web modals: header, scrolling body, footer.
Future<T?> showTrainingSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showAppBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

class TrainingSheetFrame extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final List<Widget> children;
  final List<Widget> actions;

  const TrainingSheetFrame({
    super.key,
    required this.title,
    this.description,
    this.icon,
    required this.children,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
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
                    if (icon != null) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryTeal,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                    ],
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Labelled single-line input in the web `Input` look.
class TrainingTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? helper;
  final String? error;
  final bool required;
  final bool numeric;
  final int? maxLength;
  final int minLines;
  final ValueChanged<String>? onChanged;

  const TrainingTextField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.helper,
    this.error,
    this.required = false,
    this.numeric = false,
    this.maxLength,
    this.minLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: error != null ? AppColors.criticalRed : AppColors.searchBorder),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) ...[
          TrainingLabel(label, required: required),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : minLines + 4,
          maxLength: maxLength,
          onChanged: onChanged,
          keyboardType: numeric ? TextInputType.number : null,
          inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            hintText: placeholder,
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: border,
            enabledBorder: border,
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

class TrainingLabel extends StatelessWidget {
  final String text;
  final bool required;

  const TrainingLabel(this.text, {super.key, this.required = false});

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

/// Date (and optionally time) field opening the platform pickers.
class TrainingDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool withTime;
  final String? helper;
  final ValueChanged<DateTime?> onChanged;

  const TrainingDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.withTime = false,
    this.helper,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (day == null || !context.mounted) return;
    if (!withTime) {
      onChanged(DateTime(day.year, day.month, day.day));
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: value == null ? const TimeOfDay(hour: 9, minute: 0) : TimeOfDay.fromDateTime(value!),
    );
    if (time == null) return;
    onChanged(DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? null
        : withTime
            ? TrainingLabels.dateTime(value)
            : TrainingLabels.date(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainingLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text ?? (withTime ? 'dd/mm/yyyy --:--' : 'dd/mm/yyyy'),
                    style: handoverText(
                      context,
                      13.5,
                      color: text == null ? AppColors.textMuted : AppColors.textHeading,
                    ),
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                  )
                else
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
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

/// Web `Switch` row: label, description and toggle.
class TrainingSwitchRow extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const TrainingSwitchRow({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: handoverText(context, 13.5, weight: FontWeight.w600)),
              if (description != null)
                Text(description!, style: handoverText(context, 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeTrackColor: AppColors.secondaryTeal,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Web choice cards (`Assign To`, `Training Type`, `Expiry / Renewal Period`).
class TrainingChoiceCards extends StatelessWidget {
  final String label;
  final bool required;
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;
  final int columns;

  const TrainingChoiceCards({
    super.key,
    required this.label,
    this.required = false,
    required this.options,
    required this.value,
    required this.onChanged,
    this.columns = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainingLabel(label, required: required),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (option, description) in options)
                  SizedBox(
                    width: width,
                    child: _ChoiceCard(
                      key: ValueKey('training-choice-$option'),
                      label: option,
                      description: description,
                      selected: option == value,
                      onTap: () => onChanged(option),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    super.key,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.quickActionCreateShiftBg : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.secondaryTeal : AppColors.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: handoverText(context, 13, weight: FontWeight.w700)),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(description, style: handoverText(context, 11, color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: AppColors.secondaryTeal, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Web numeric stepper (`-` / value / suffix / `+`).
class TrainingStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  const TrainingStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String semantic, int delta) => Semantics(
          label: semantic,
          button: true,
          child: InkWell(
            onTap: () => onChanged((value + delta).clamp(min, max)),
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.searchBorder),
              ),
              child: Icon(icon, size: 14, color: AppColors.textSecondary),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainingLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            children: [
              button(Icons.remove_rounded, 'Decrease', -1),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: handoverText(context, 14, weight: FontWeight.w600),
                ),
              ),
              Text(suffix, style: handoverText(context, 12.5, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              button(Icons.add_rounded, 'Increase', 1),
            ],
          ),
        ),
      ],
    );
  }
}

/// Web `MultiSelectChips`: chips with remove, "+N more", and an "Add…"
/// picker of checkable options.
class TrainingMultiPicker extends StatelessWidget {
  final String label;
  final String? helper;
  final String? error;
  final List<(String, String)> options;
  final List<String> value;
  final ValueChanged<List<String>> onChanged;
  final String placeholder;
  final bool searchable;
  final int maxChipsShown;

  const TrainingMultiPicker({
    super.key,
    required this.label,
    this.helper,
    this.error,
    required this.options,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Add…',
    this.searchable = false,
    this.maxChipsShown = 3,
  });

  void _toggle(String id) =>
      onChanged(value.contains(id) ? value.where((v) => v != id).toList() : [...value, id]);

  Future<void> _open(BuildContext context) async {
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MultiPickerSheet(
        title: label,
        options: options,
        initial: value,
        searchable: searchable,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = options.where((o) => value.contains(o.$1)).toList();
    final shown = selected.take(maxChipsShown).toList();
    final more = selected.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainingLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: error != null ? AppColors.criticalRed : AppColors.searchBorder),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (id, text) in shown)
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
                  decoration: BoxDecoration(
                    color: AppColors.quickActionCreateShiftBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text,
                          style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.secondaryTeal)),
                      const SizedBox(width: 4),
                      Semantics(
                        label: 'Remove $text',
                        button: true,
                        child: GestureDetector(
                          onTap: () => _toggle(id),
                          child: const Icon(Icons.close_rounded, size: 13, color: AppColors.secondaryTeal),
                        ),
                      ),
                    ],
                  ),
                ),
              if (more > 0)
                Text('+$more more', style: handoverText(context, 12, color: AppColors.textMuted)),
              InkWell(
                key: ValueKey('training-picker-$label'),
                onTap: () => _open(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.searchBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(placeholder, style: handoverText(context, 12, color: AppColors.textMuted)),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
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

class _MultiPickerSheet extends StatefulWidget {
  final String title;
  final List<(String, String)> options;
  final List<String> initial;
  final bool searchable;
  final ValueChanged<List<String>> onChanged;

  const _MultiPickerSheet({
    required this.title,
    required this.options,
    required this.initial,
    required this.searchable,
    required this.onChanged,
  });

  @override
  State<_MultiPickerSheet> createState() => _MultiPickerSheetState();
}

class _MultiPickerSheetState extends State<_MultiPickerSheet> {
  late List<String> _value = [...widget.initial];
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = widget.searchable && q.isNotEmpty
        ? widget.options.where((o) => o.$2.toLowerCase().contains(q)).toList()
        : widget.options;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(widget.title, style: handoverText(context, 16, weight: FontWeight.w700)),
              ),
              if (widget.searchable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: handoverText(context, 13.5),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                ),
              Flexible(
                child: visible.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          widget.searchable && q.isNotEmpty ? 'No matches' : 'No staff available',
                          textAlign: TextAlign.center,
                          style: handoverText(context, 12.5, color: AppColors.textMuted),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final (id, text) in visible)
                            CheckboxListTile(
                              value: _value.contains(id),
                              activeColor: AppColors.secondaryTeal,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(text, style: handoverText(context, 14)),
                              onChanged: (_) {
                                setState(() {
                                  _value = _value.contains(id)
                                      ? _value.where((v) => v != id).toList()
                                      : [..._value, id];
                                });
                                widget.onChanged(_value);
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

/// Web `ConfirmDialog` (danger tone). [onConfirm] returns true to close.
Future<void> showTrainingConfirm(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  required Future<bool> Function() onConfirm,
}) {
  return showAppPopup<void>(
    context: context,
    builder: (_) => _ConfirmDialog(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
      onConfirm: onConfirm,
    ),
  );
}

class _ConfirmDialog extends StatefulWidget {
  final String title;
  final String description;
  final String confirmLabel;
  final Future<bool> Function() onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return AppSheetDialog(
      backgroundColor: AppColors.surfaceWhite,
      title: Text(widget.title, style: handoverText(context, 17, weight: FontWeight.w700)),
      content: Text(
        widget.description,
        style: handoverText(context, 13.5, color: AppColors.textSecondary),
      ),
      actions: [
        HandoverButton(
          label: 'Cancel',
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        Material(
          color: AppColors.criticalRed,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            key: const ValueKey('training-confirm'),
            borderRadius: BorderRadius.circular(9),
            onTap: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final close = await widget.onConfirm();
                    if (!context.mounted) return;
                    if (close) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _busy = false);
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                _busy ? 'Please wait…' : widget.confirmLabel,
                style: handoverText(context, 13.5, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// White page header with back arrow, title and trailing actions.
class TrainingHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const TrainingHeader({super.key, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textHeading),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: handoverText(context, 18, weight: FontWeight.w700),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
