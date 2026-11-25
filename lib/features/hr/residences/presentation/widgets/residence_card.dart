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

/// Web residence status menu: Active, Pending, Inactive.
class _ResidenceStatusOption {
  final String value;
  final String label;
  final String detail;
  final Color color;

  const _ResidenceStatusOption(this.value, this.label, this.detail, this.color);
}

const _statusOptions = [
  _ResidenceStatusOption(
    'active',
    'Active',
    'Current status',
    AppColors.activeGreen,
  ),
  _ResidenceStatusOption(
    'pending',
    'Pending',
    'Being set up, not open yet',
    AppColors.urgentAmber,
  ),
  _ResidenceStatusOption(
    'inactive',
    'Inactive',
    'Out of service, hidden from staff',
    AppColors.textSecondary,
  ),
];

/// One row of the web residences table: name / address, type / service,
/// capacity, assigned staff, primary manager, status, GPS radius, Actions.
class ResidenceCard extends StatelessWidget {
  final ResidenceSummary residence;
  final VoidCallback? onTap;

  /// Entries to offer in the Actions menu; empty hides the menu.
  final List<ResidenceRowAction> actions;
  final ValueChanged<ResidenceRowAction>? onAction;

  /// When set, the status pill offers the same Active / out-of-service
  /// choice as the row menu (`active` or `inactive`).
  final ValueChanged<String>? onStatus;
  final bool busy;

  const ResidenceCard({
    super.key,
    required this.residence,
    this.onTap,
    this.actions = const [],
    this.onAction,
    this.onStatus,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = residence;
    return SurfaceCard.card(
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
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
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
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                _status(context),
                if (actions.isNotEmpty) _menu(context),
              ],
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          ],
        ),
    );
  }

  Widget _status(BuildContext context) {
    final tone = ResidencesLabels.statusTone(residence.status);
    final pill = Container(
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
          Text(
            residence.statusLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: tone.foreground,
            ),
          ),
          if (onStatus != null && !busy) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 14),
              color: tone.foreground,
            ),
          ],
        ],
      ),
    );
    if (onStatus == null || busy) return pill;
    final current = residence.status.toLowerCase();
    return PopupMenuButton<String>(
      key: ValueKey('residence-status-${residence.id}'),
      tooltip: 'Change status',
      padding: EdgeInsets.zero,
      color: AppColors.surfaceWhite,
      onSelected: (value) {
        if (value == current) return;
        onStatus!(value);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 32,
          child: Text(
            'Change status',
            style: _style(context, 12, AppFontWeight.medium, AppColors.textSecondary),
          ),
        ),
        for (final option in _statusOptions)
          PopupMenuItem<String>(
            value: option.value,
            height: 56,
            child: _statusOption(context, option, selected: option.value == current),
          ),
      ],
      child: pill,
    );
  }

  Widget _statusOption(
    BuildContext context,
    _ResidenceStatusOption option, {
    required bool selected,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: option.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.label,
                style: _style(context, 13.5, AppFontWeight.semiBold, AppColors.textHeading),
              ),
              Text(
                option.detail,
                style: _style(context, 11, AppFontWeight.regular, AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (selected)
          const Icon(Icons.check_rounded, size: 16, color: AppColors.activeGreen),
      ],
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
