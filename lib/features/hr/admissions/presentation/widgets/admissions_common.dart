import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';

/// The web badge variants used on the admissions screens.
enum AdmissionTone { info, cyan, warning, purple, success, danger, neutral }

extension AdmissionToneColors on AdmissionTone {
  Color get foreground => switch (this) {
        AdmissionTone.info => AppColors.infoBlue,
        AdmissionTone.cyan => const Color(0xFF0E7490),
        AdmissionTone.warning => AppColors.urgentAmber,
        AdmissionTone.purple => AppColors.nightPurple,
        AdmissionTone.success => AppColors.activeGreen,
        AdmissionTone.danger => AppColors.criticalRed,
        AdmissionTone.neutral => AppColors.textSecondary,
      };

  Color get background => switch (this) {
        AdmissionTone.info => AppColors.infoBackground,
        AdmissionTone.cyan => const Color(0xFFE6F6FA),
        AdmissionTone.warning => AppColors.urgentBackground,
        AdmissionTone.purple => AppColors.nightBackground,
        AdmissionTone.success => AppColors.activeBackground,
        AdmissionTone.danger => AppColors.criticalBackgroundSoft,
        AdmissionTone.neutral => AppColors.filterButtonBackground,
      };
}

class AdmissionPill extends StatelessWidget {
  final String label;
  final AdmissionTone tone;
  final bool dot;

  const AdmissionPill({
    super.key,
    required this.label,
    required this.tone,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 8,
        vertical: 3,
      ),
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
              decoration: BoxDecoration(
                color: tone.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: handoverText(
              context,
              11,
              weight: FontWeight.w600,
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _label(BuildContext context, String label, bool required) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
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
    );

Widget _helper(BuildContext context, String? helper, String? error) {
  if (error != null) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        error,
        style: handoverText(context, 12, color: AppColors.criticalRed),
      ),
    );
  }
  if (helper == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(
      helper,
      style: handoverText(context, 12, color: AppColors.textMuted),
    ),
  );
}

/// Labelled single-line input (the web `TextInput`).
class AdmissionInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? helper;
  final String? error;
  final bool required;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const AdmissionInput({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.helper,
    this.error,
    this.required = false,
    this.enabled = true,
    this.keyboardType,
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
        if (label.isNotEmpty) _label(context, label, required),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
              : null,
          onChanged: onChanged,
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: placeholder,
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            filled: true,
            fillColor:
                enabled ? AppColors.surfaceWhite : AppColors.filterButtonBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: border(AppColors.searchBorder),
            enabledBorder: border(
              error == null ? AppColors.searchBorder : AppColors.criticalRed,
            ),
            disabledBorder: border(AppColors.searchBorder),
          ),
        ),
        _helper(context, helper, error),
      ],
    );
  }
}

/// Labelled date field that opens the platform picker; the value is the
/// web's `YYYY-MM-DD` date-only string.
class AdmissionDateField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? helper;
  final bool required;
  final bool enabled;
  final DateTime? lastDate;

  const AdmissionDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.required = false,
    this.enabled = true,
    this.lastDate,
  });

  static String format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? parse(String value) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = parse(value);
    return HandoverSelect(
      label: label,
      required: required,
      value: current == null ? null : WebFormat.date(current),
      placeholder: 'Pick a date',
      helper: helper,
      onTap: !enabled
          ? null
          : () async {
              final last = lastDate ?? DateTime(2100);
              final initial = current ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initial.isAfter(last) ? last : initial,
                firstDate: DateTime(1900),
                lastDate: last,
              );
              if (picked != null) onChanged(format(picked));
            },
    );
  }
}

/// The web `Checkbox` with a label beside it.
class AdmissionCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdmissionCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: AppColors.secondaryTeal,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged:
                    onChanged == null ? null : (v) => onChanged!(v == true),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, style: handoverText(context, 13.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Red inline alert used by every admissions modal.
class AdmissionErrorBanner extends StatelessWidget {
  final String message;

  const AdmissionErrorBanner(this.message, {super.key});

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

/// Muted grey notice ("This referral is already closed.").
class AdmissionNotice extends StatelessWidget {
  final String message;

  const AdmissionNotice(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: handoverText(context, 13, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Small uppercase grey section heading.
class AdmissionSectionTitle extends StatelessWidget {
  final String title;

  const AdmissionSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: handoverText(
        context,
        12,
        weight: FontWeight.w600,
        color: const Color(0xFF94A3B8),
      ).copyWith(letterSpacing: 0.6),
    );
  }
}

/// A `dt` / `dd` pair.
class AdmissionField extends StatelessWidget {
  final String label;
  final String value;

  const AdmissionField(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: handoverText(
              context,
              12,
              weight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: handoverText(context, 13.5)),
        ],
      ),
    );
  }
}

/// Bottom-sheet shell matching the web modal: icon header with title and
/// description, scrolling body and a right-aligned footer.
class AdmissionSheetFrame extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final List<Widget> children;
  final List<Widget> footer;
  final bool tall;

  const AdmissionSheetFrame({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.children,
    required this.footer,
    this.tall = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final body = ListView(
      shrinkWrap: !tall,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 14,
      ),
      children: children,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: tall ? media.size.height * 0.92 : null,
          constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: tall ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.quickActionCreateShiftBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 19, color: AppColors.secondaryTeal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: handoverText(
                              context,
                              16,
                              weight: FontWeight.w600,
                            ),
                          ),
                          if (description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              description!,
                              style: handoverText(
                                context,
                                13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (tall) Expanded(child: body) else Flexible(child: body),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + media.padding.bottom,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: footer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showAdmissionSheet<T>(BuildContext context, Widget sheet) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );

/// Filled red or amber confirm button.
class AdmissionToneButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AdmissionToneButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: AppColors.surfaceWhite),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: handoverText(
                    context,
                    13.5,
                    weight: FontWeight.w600,
                    color: AppColors.surfaceWhite,
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

/// The web `ConfirmDialog`. Resolves to true when confirmed.
Future<bool> confirmAdmissionAction(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  required Color tone,
  required Key confirmKey,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      title: Text(
        title,
        style: handoverText(dialogContext, 17, weight: FontWeight.w700),
      ),
      content: Text(
        description,
        style:
            handoverText(dialogContext, 13.5, color: AppColors.textSecondary),
      ),
      actions: [
        HandoverButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AdmissionToneButton(
          key: confirmKey,
          label: confirmLabel,
          color: tone,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed == true;
}
