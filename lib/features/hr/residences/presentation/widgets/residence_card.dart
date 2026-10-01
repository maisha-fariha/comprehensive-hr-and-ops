import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../domain/entities/residence_summary.dart';
import '../residences_labels.dart';

/// Row Actions menu entries of the web residences table.
enum ResidenceRowAction { view, edit, toggleStatus, delete }

/// One row of the web residences table: name / address, type / service,
/// capacity, assigned staff, primary manager, status, GPS radius, Actions.
class ResidenceCard extends StatelessWidget {
  final ResidenceSummary residence;
  final VoidCallback? onTap;

  /// Entries to offer in the Actions menu; empty hides the menu.
  final List<ResidenceRowAction> actions;
  final ValueChanged<ResidenceRowAction>? onAction;
  final bool busy;

  const ResidenceCard({
    super.key,
    required this.residence,
    this.onTap,
    this.actions = const [],
    this.onAction,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = residence;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: AppDimens.cardPaddingHorizontal,
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: _style(context, 15, AppFontWeight.semiBold, AppColors.textHeading),
                      ),
                      if (r.address != null) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                        Text(
                          r.address!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _style(context, 12, AppFontWeight.regular, AppColors.infoBlue),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                AttendancePill(
                  label: r.statusLabel,
                  tone: ResidencesLabels.statusTone(r.status),
                ),
                if (actions.isNotEmpty) _menu(context),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            _line(
              context,
              'Type',
              r.residenceType == null ? '—' : hrHumanize(r.residenceType),
              sub: r.serviceType,
            ),
            _line(
              context,
              'Capacity',
              '${r.residents} / ${r.bedCapacity} Beds',
              color: r.atCapacity ? AppColors.criticalRed : null,
            ),
            _line(context, 'Assigned Staff', '${r.assignedStaffCount} Members'),
            _line(context, 'Primary Manager', r.primaryManager?.name ?? '—'),
            _line(
              context,
              'GPS Radius',
              r.gpsRadiusMeters == null ? '—' : '${r.gpsRadiusMeters}m',
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 28,
      child: busy
          ? const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondaryTeal),
              ),
            )
          : PopupMenuButton<ResidenceRowAction>(
              key: ValueKey('residence-actions-${residence.id}'),
              padding: EdgeInsets.zero,
              tooltip: 'Actions',
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
              color: AppColors.surfaceWhite,
              onSelected: onAction,
              itemBuilder: (_) => [
                for (final action in actions)
                  PopupMenuItem(
                    value: action,
                    child: _menuRow(context, action),
                  ),
              ],
            ),
    );
  }

  Widget _menuRow(BuildContext context, ResidenceRowAction action) {
    final (icon, label, danger) = switch (action) {
      ResidenceRowAction.view => (Icons.visibility_outlined, 'View', false),
      ResidenceRowAction.edit => (Icons.edit_outlined, 'Edit', false),
      ResidenceRowAction.toggleStatus => residence.isActive
          ? (Icons.block_rounded, 'Take out of service', false)
          : (Icons.check_circle_outline_rounded, 'Activate', false),
      ResidenceRowAction.delete => (Icons.delete_outline_rounded, 'Delete', true),
    };
    final color = danger ? AppColors.criticalRed : AppColors.textHeading;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label, style: _style(context, 13.5, AppFontWeight.medium, color)),
      ],
    );
  }

  Widget _line(
    BuildContext context,
    String label,
    String value, {
    String? sub,
    Color? color,
  }) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveHelper.getResponsiveWidth(context, 112),
            child: Text(
              label,
              style: _style(context, 12, AppFontWeight.medium, AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: _style(context, 12.5, AppFontWeight.semiBold, color ?? AppColors.textHeading),
                ),
                if (sub != null)
                  Text(sub, style: _style(context, 11.5, AppFontWeight.regular, AppColors.infoBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _style(BuildContext context, double size, FontWeight weight, Color color) =>
      AppTextStyles.base(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, size),
        fontWeight: weight,
        color: color,
      );
}
