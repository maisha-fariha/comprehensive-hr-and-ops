import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Web `StatCard` used by the Residences KPI tiles.
class ResidenceKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String bottom;
  final bool danger;

  const ResidenceKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.bottom,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      borderColor: danger ? AppColors.criticalRed.withValues(alpha: 0.35) : AppColors.cardBorder,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: handoverText(context, 13, weight: FontWeight.w500, color: AppColors.infoBlue),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: handoverText(
              context,
              26,
              weight: FontWeight.w700,
              color: danger ? AppColors.criticalRed : AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bottom,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Two-column grid that keeps tiles equal height per row.
class ResidenceTileGrid extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const ResidenceTileGrid({super.key, required this.children, this.gap = 12});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: gap),
              Expanded(
                child: i + 1 < children.length ? children[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// Detail-drawer stat card: uppercase label, value and a hint.
class ResidenceStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData? icon;
  final bool critical;

  const ResidenceStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    this.icon,
    this.critical = false,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: handoverText(
                    context,
                    11,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: handoverText(
              context,
              22,
              weight: FontWeight.w700,
              color: critical ? AppColors.criticalRed : AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 2),
          Text(hint, style: handoverText(context, 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Web `td`: label on the left, value on the right, divider below.
class ResidenceInfoLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const ResidenceInfoLine({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 6),
          ],
          Text(label, style: handoverText(context, 12.5, color: AppColors.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: handoverText(context, 12.5, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// White card with a section title (web `e0` card + `ti` heading).
class ResidenceSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ResidenceSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: handoverText(context, 14, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Small uppercase heading used above tab lists.
class ResidenceCaption extends StatelessWidget {
  final String text;

  const ResidenceCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: handoverText(
          context,
          12,
          weight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      );
}

/// Muted centred message used for empty / error states inside tabs.
class ResidenceMutedMessage extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;

  const ResidenceMutedMessage({super.key, required this.title, this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(height: 6),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: handoverText(
              context,
              message == null ? 13.5 : 15,
              weight: message == null ? FontWeight.w400 : FontWeight.w600,
              color: message == null ? AppColors.textMuted : AppColors.textHeading,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: handoverText(context, 13.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Coloured initials circle (web `eX` palette).
class ResidenceInitials extends StatelessWidget {
  final String initials;
  final int index;

  const ResidenceInitials({super.key, required this.initials, required this.index});

  static const _palette = [
    (Color(0xFFEAF0F9), Color(0xFF2A5DA6)),
    (Color(0xFFF1EAFE), Color(0xFF7656D6)),
    (Color(0xFFE7F4F4), Color(0xFF0E7C7B)),
    (Color(0xFFFFF7E8), Color(0xFFE9A23B)),
    (Color(0xFFFBEAEA), Color(0xFFD64545)),
  ];

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _palette[index % _palette.length];
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(initials, style: handoverText(context, 11, weight: FontWeight.w600, color: fg)),
    );
  }
}

/// Web confirm dialog "Delete this home?".
Future<bool> confirmResidenceDelete(BuildContext context) async {
  final confirmed = await showAppPopup<bool>(
    context: context,
    builder: (dialogContext) => AppSheetDialog(
      backgroundColor: AppColors.surfaceWhite,
      title: Text(
        'Delete this home?',
        style: handoverText(dialogContext, 17, weight: FontWeight.w700),
      ),
      content: Text(
        'It leaves the list. The home, and everything recorded at it, is kept '
        'rather than destroyed, so it can be restored.',
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
            key: const ValueKey('residence-delete-confirm'),
            borderRadius: BorderRadius.circular(9),
            onTap: () => Navigator.of(dialogContext).pop(true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Delete',
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
