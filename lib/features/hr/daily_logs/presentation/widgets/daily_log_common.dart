import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../recurring_checks/presentation/widgets/check_common.dart';
import '../daily_logs_labels.dart';

class DailyLogPill extends StatelessWidget {
  final String label;
  final DailyLogTone tone;

  const DailyLogPill(this.label, {super.key, this.tone = DailyLogTone.neutral});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: handoverText(context, 11, weight: FontWeight.w600, color: tone.foreground),
      ),
    );
  }
}

/// Labelled select opening a bottom-sheet list; [onClear] resets it.
class DailyLogSelect extends StatelessWidget {
  final String label;
  final String value;
  final String placeholder;
  final bool required;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String? error;

  const DailyLogSelect({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    this.required = false,
    this.onTap,
    this.onClear,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckFieldLabel(label, required: required),
        const SizedBox(height: 6),
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
                border: Border.all(
                  color: error == null ? AppColors.searchBorder : AppColors.criticalRed,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      empty ? placeholder : value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      child: const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
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
        if (error != null) DailyLogFieldError(error!),
      ],
    );
  }
}

class DailyLogFieldError extends StatelessWidget {
  final String message;

  const DailyLogFieldError(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          message,
          style: handoverText(context, 12, color: AppColors.criticalRed),
        ),
      );
}

/// Centered "Choose a residence to begin"-style card.
class DailyLogEmptyCard extends StatelessWidget {
  final String title;
  final String description;

  const DailyLogEmptyCard({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: handoverText(context, 15, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: handoverText(context, 13.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Upper-case label over a value, `—` when empty.
class DailyLogDetail extends StatelessWidget {
  final String label;
  final String? value;

  const DailyLogDetail(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final text = value == null || value!.isEmpty ? '—' : value!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(text, style: handoverText(context, 13)),
      ],
    );
  }
}

/// Muted box with an upper-case caption ("Original entry", flag category).
class DailyLogQuote extends StatelessWidget {
  final String caption;
  final String text;

  const DailyLogQuote({super.key, required this.caption, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption.toUpperCase(),
            style: handoverText(context, 11.5, weight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(text, style: handoverText(context, 13)),
        ],
      ),
    );
  }
}

class DailyLogFormError extends StatelessWidget {
  final String message;

  const DailyLogFormError(this.message, {super.key});

  @override
  Widget build(BuildContext context) => CheckNotice(
        child: Text(message, style: handoverText(context, 13.5, color: AppColors.criticalRed)),
      );
}

DateTime? _parseDay(String key) => DateTime.tryParse(key);

/// Date picker over `YYYY-MM-DD` keys, bounded by [min] / [max].
Future<String?> pickDailyLogDay(
  BuildContext context,
  String current, {
  String? min,
  String? max,
}) async {
  final now = DateTime.now();
  final first = (min == null ? null : _parseDay(min)) ?? DateTime(now.year - 5);
  final last = (max == null ? null : _parseDay(max)) ?? DateTime(now.year + 2);
  var initial = _parseDay(current) ?? now;
  if (initial.isBefore(first)) initial = first;
  if (initial.isAfter(last)) initial = last;
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
  );
  if (picked == null) return null;
  return '${picked.year}-${picked.month.toString().padLeft(2, '0')}-'
      '${picked.day.toString().padLeft(2, '0')}';
}

/// Date then time, as a web `datetime-local` input.
Future<DateTime?> pickDailyLogDateTime(BuildContext context, DateTime? current) async {
  final now = DateTime.now();
  final base = current ?? now;
  final date = await showDatePicker(
    context: context,
    initialDate: base,
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 2),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base));
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Picks one of [options]; returns `null` when dismissed.
Future<String?> pickDailyLogOption(
  BuildContext context,
  String title,
  List<(String, String)> options,
  String selected,
) =>
    pickHandoverOption(context, title: title, options: options, selected: selected);
