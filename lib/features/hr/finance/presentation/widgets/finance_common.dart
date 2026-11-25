import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/finance_mapper.dart';

export '../../../attendance/presentation/widgets/attendance_pagination.dart'
    show AttendancePagination;

Widget financeSectionTitle(
  BuildContext context,
  String title, {
  String? subtitle,
  List<Widget>? actions,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: handoverText(context, 16, weight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
      if (actions != null) ...actions,
    ],
  );
}

class FinanceStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  final Color? noteColor;
  final VoidCallback? onTap;

  const FinanceStatCard({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.noteColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: handoverText(context, 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(value, style: handoverText(context, 17, weight: FontWeight.w700)),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(
              note!,
              style: handoverText(
                context,
                11,
                color: noteColor ?? AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: child);
  }
}

class FinanceInfoBanner extends StatelessWidget {
  final String text;
  final Color? tone;

  const FinanceInfoBanner(this.text, {super.key, this.tone});

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColors.infoBlue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: handoverText(context, 13, color: color)),
    );
  }
}

class FinanceStatusPill extends StatelessWidget {
  final String status;
  const FinanceStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final tone = switch (status.toLowerCase()) {
      'finalized' || 'paid' || 'approved' || 'active' || 'included' =>
        AppColors.activeGreen,
      'draft' || 'pending' || 'processing' => AppColors.urgentAmber,
      'rejected' || 'disconnected' => AppColors.criticalRed,
      _ => AppColors.infoBlue,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        FinanceLabels.statusLabel(status),
        style: handoverText(context, 11, weight: FontWeight.w600, color: tone),
      ),
    );
  }
}

class FinanceAvatar extends StatelessWidget {
  final String name;
  const FinanceAvatar(this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.secondaryTeal,
      child: Text(
        FinanceLabels.initials(name),
        style: handoverText(context, 11, weight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class FinanceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FinanceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

Future<void> copyFinanceText(String text, {String ok = 'Copied'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  AppSnackbar.show(ok, '', force: true);
}

Future<T?> showFinancePicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  T? selected,
}) async {
  return showAppBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(title, style: handoverText(ctx, 15, weight: FontWeight.w700)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options[i];
                  final selectedNow = selected == opt;
                  return ListTile(
                    title: Text(labelOf(opt)),
                    trailing: selectedNow
                        ? const Icon(Icons.check, color: AppColors.secondaryTeal)
                        : null,
                    onTap: () => Navigator.pop(ctx, opt),
                  );
                },
              ),
            ),
          ],
      );
    },
  );
}
