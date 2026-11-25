import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

/// Web PRN "Shortest gap between doses" — hour presets + hrs/mins inputs.
/// Always stores the API value as total minutes via [totalMinutes].
class PrnShortestGapField extends StatelessWidget {
  static const presetsHours = [1, 2, 4, 6, 8, 12, 24];

  final TextEditingController hours;
  final TextEditingController minutes;
  final VoidCallback onChanged;
  final InputDecoration Function({String? hint, Widget? suffix}) decoration;
  final TextStyle fieldStyle;
  final bool required;

  const PrnShortestGapField({
    super.key,
    required this.hours,
    required this.minutes,
    required this.onChanged,
    required this.decoration,
    required this.fieldStyle,
    this.required = true,
  });

  /// Split API minutes into hours + minutes controllers.
  static void applyMinutes(
    int? total, {
    required TextEditingController hours,
    required TextEditingController minutes,
  }) {
    if (total == null || total <= 0) {
      hours.clear();
      minutes.clear();
      return;
    }
    hours.text = (total ~/ 60).toString();
    final mins = total % 60;
    minutes.text = mins == 0 ? '' : mins.toString();
  }

  /// Total minutes from the hrs/mins fields (null when both empty / invalid).
  static int? totalMinutes({
    required TextEditingController hours,
    required TextEditingController minutes,
  }) {
    final h = int.tryParse(hours.text.trim()) ?? 0;
    final m = int.tryParse(minutes.text.trim()) ?? 0;
    if (hours.text.trim().isEmpty && minutes.text.trim().isEmpty) return null;
    if (h < 0 || m < 0 || m > 59) return null;
    final total = h * 60 + m;
    return total > 0 ? total : null;
  }

  void _setPreset(int hrs) {
    hours.text = hrs.toString();
    minutes.text = '0';
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final selected = totalMinutes(hours: hours, minutes: minutes);
    final selectedHours =
        selected != null && selected % 60 == 0 ? selected ~/ 60 : null;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Shortest gap between doses',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textHeading,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.criticalRed,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const Text(
              'Common:',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            for (final h in presetsHours)
              _PresetChip(
                label: h == 1 ? '1 hr' : '$h hrs',
                selected: selectedHours == h,
                onTap: () => _setPreset(h),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('prn-gap-hours'),
                controller: hours,
                style: fieldStyle,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: decoration(
                  hint: 'Hours',
                  suffix: const _UnitSuffix('hrs'),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey('prn-gap-minutes'),
                controller: minutes,
                style: fieldStyle,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: decoration(
                  hint: 'Minutes',
                  suffix: const _UnitSuffix('mins'),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          required
              ? 'Required for PRN medicines. Select a preset or enter '
                  'hours/minutes (e.g. 4 hours for Paracetamol).'
              : 'Select a preset or enter hours/minutes '
                  '(e.g. 4 hours for Paracetamol).',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.5,
            height: 1.35,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );

    // Web nests this control in its own outlined card.
    return Container(
      key: const ValueKey('prn-shortest-gap'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: body,
    );
  }
}

class _UnitSuffix extends StatelessWidget {
  final String label;

  const _UnitSuffix(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.secondaryTeal.withValues(alpha: 0.14)
          : AppColors.quickActionCreateShiftBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.secondaryTeal
                  : AppColors.searchBorder.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: selected
                  ? AppColors.secondaryTeal
                  : AppColors.textHeading,
            ),
          ),
        ),
      ),
    );
  }
}
