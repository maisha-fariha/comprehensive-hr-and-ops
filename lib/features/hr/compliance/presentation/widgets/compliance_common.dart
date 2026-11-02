import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';

export '../../../attendance/presentation/widgets/attendance_pagination.dart'
    show AttendancePagination;

Widget complianceSectionTitle(
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

class ComplianceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ComplianceCard({
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

class ComplianceStatChip extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  final Color? accent;

  const ComplianceStatChip({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.secondaryTeal;
    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
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
          Text(
            value,
            style: handoverText(context, 20, weight: FontWeight.w700, color: color),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!, style: handoverText(context, 11, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class ComplianceStatusPill extends StatelessWidget {
  final String status;
  const ComplianceStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final tone = switch (status.toLowerCase()) {
      'open' || 'outstanding' || 'pending' || 'medium' => AppColors.urgentAmber,
      'overdue' || 'critical' || 'high' || 'failing' => AppColors.criticalRed,
      'resolved' || 'completed' || 'verified' || 'low' || 'pass' || 'passed' =>
        AppColors.activeGreen,
      _ => AppColors.infoBlue,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ComplianceMapper.label(status),
        style: handoverText(context, 11, weight: FontWeight.w600, color: tone),
      ),
    );
  }
}

class ComplianceEmpty extends StatelessWidget {
  final String message;
  final IconData icon;
  const ComplianceEmpty({
    super.key,
    required this.message,
    this.icon = Icons.assignment_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return ComplianceCard(
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: handoverText(context, 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

Future<T?> showCompliancePicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Text(
                  title,
                  style: handoverText(ctx, 16, weight: FontWeight.w700),
                ),
              ),
              for (final opt in options)
                ListTile(
                  title: Text(labelOf(opt)),
                  trailing: identical(opt, selected) || opt == selected
                      ? const Icon(Icons.check, color: AppColors.secondaryTeal)
                      : null,
                  onTap: () => Navigator.pop(ctx, opt),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Widget compliancePagination({
  required int page,
  required int limit,
  required int total,
  required int totalPages,
  required ValueChanged<int> onPage,
  required ValueChanged<int> onLimit,
}) {
  return AttendancePagination(
    page: page,
    limit: limit,
    total: total,
    totalPages: totalPages,
    limitOptions: ComplianceMapper.pageSizes,
    onPage: onPage,
    onLimit: onLimit,
  );
}
