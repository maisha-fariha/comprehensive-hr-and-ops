import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../daily_activity_labels.dart';

class DailyActivityPill extends StatelessWidget {
  final String label;
  final DailyActivityTone tone;

  const DailyActivityPill({super.key, required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: handoverText(context, 11.5, weight: FontWeight.w600, color: tone.foreground),
      ),
    );
  }
}

class DailyActivityInitials extends StatelessWidget {
  final String text;
  final double size;

  const DailyActivityInitials({super.key, required this.text, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondaryTeal.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: handoverText(
          context,
          size * 0.38,
          weight: FontWeight.w700,
          color: AppColors.secondaryTeal,
        ),
      ),
    );
  }
}

/// Filter select: shows the current label, opens a picker sheet.
class DailyActivitySelect extends StatelessWidget {
  final String title;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const DailyActivitySelect({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        options.where((o) => o.$1 == selected).map((o) => o.$2).firstOrNull ?? options.first.$2;
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
            selected: selected,
          );
          if (picked != null && picked != selected) onChanged(picked);
        },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: handoverText(context, 13.5, weight: FontWeight.w500),
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
    );
  }
}

/// The web `destructive` button.
class DailyActivityDangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const DailyActivityDangerButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.criticalRed,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: handoverText(
              context,
              13.5,
              weight: FontWeight.w600,
              color: AppColors.surfaceWhite,
            ),
          ),
        ),
      ),
    );
  }
}

class DailyActivityEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color messageColor;

  const DailyActivityEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.messageColor = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
            style: handoverText(context, 13.5, color: messageColor),
          ),
        ],
      ),
    );
  }
}
