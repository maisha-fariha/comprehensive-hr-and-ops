import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../hr_appointments_labels.dart';

/// The web `Badge` in one of its variants.
class HrAppointmentPill extends StatelessWidget {
  final String label;
  final HrAppointmentTone tone;
  final IconData? icon;

  const HrAppointmentPill({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: tone.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: handoverText(context, 12, weight: FontWeight.w600, color: tone.foreground),
          ),
        ],
      ),
    );
  }
}

/// Upper-case label over a bold value; a dash when the value is empty.
class HrAppointmentInfo extends StatelessWidget {
  final String label;
  final String? value;

  const HrAppointmentInfo(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted)
              .copyWith(letterSpacing: 0.4),
        ),
        const SizedBox(height: 3),
        Text(
          v == null || v.isEmpty ? '—' : v,
          style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
        ),
      ],
    );
  }
}

/// Lays [children] out two to a row, like the web's `sm:grid-cols-2`.
class HrAppointmentInfoGrid extends StatelessWidget {
  final List<Widget> children;

  const HrAppointmentInfoGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < children.length ? 14 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 14),
              Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// A titled white panel.
class HrAppointmentSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const HrAppointmentSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: handoverText(context, 13.5, weight: FontWeight.w700, color: AppColors.primaryNavy)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Square tinted icon used in the modal headers.
class HrAppointmentHeaderIcon extends StatelessWidget {
  const HrAppointmentHeaderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.secondaryTeal,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(Icons.edit_calendar_rounded, size: 20, color: AppColors.surfaceWhite),
    );
  }
}

/// Bottom-sheet header: icon, title, description, optional badges, close.
class HrAppointmentSheetHeader extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> badges;

  const HrAppointmentSheetHeader({
    super.key,
    required this.title,
    required this.description,
    this.badges = const [],
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
          const HrAppointmentHeaderIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: handoverText(context, 16, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description, style: handoverText(context, 13, color: AppColors.textMuted)),
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: badges),
                ],
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

/// Sticky footer holding the modal buttons, right-aligned.
class HrAppointmentSheetFooter extends StatelessWidget {
  final List<Widget> children;

  const HrAppointmentSheetFooter({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: children,
      ),
    );
  }
}

/// Red alert box used for inline errors.
class HrAppointmentErrorBox extends StatelessWidget {
  final String title;
  final String? message;

  const HrAppointmentErrorBox({super.key, required this.title, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.criticalBackgroundSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.criticalRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.criticalRed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: handoverText(context, 13, weight: FontWeight.w700, color: AppColors.criticalRed),
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(message!, style: handoverText(context, 12, color: AppColors.criticalRed)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String hrAppointmentInitials(String name) => name
    .split(' ')
    .where((p) => p.isNotEmpty)
    .map((p) => p[0])
    .take(2)
    .join()
    .toUpperCase();
