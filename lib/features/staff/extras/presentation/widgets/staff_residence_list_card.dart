import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_residence.dart';

/// Mobile card mirroring one web Residences Management table row + Actions.
class StaffResidenceListCard extends StatelessWidget {
  final StaffResidence residence;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;

  const StaffResidenceListCard({
    super.key,
    required this.residence,
    this.onView,
    this.onEdit,
    this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final address = residence.listAddress;
    final secondaryType = residence.typeSecondaryLabel;

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    residence.name.trim(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                      color: AppColors.textHeading,
                      height: 1.25,
                    ),
                  ),
                ),
                if (residence.status.trim().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: residence.isActive
                          ? AppColors.activeBackground
                          : AppColors.filterButtonBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      residence.statusLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          11,
                        ),
                        color: residence.isActive
                            ? AppColors.activeGreen
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                address,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _MetaLine(
              label: 'Type',
              value: residence.typePrimaryLabel,
              secondary: secondaryType.isEmpty ? null : secondaryType,
            ),
            _MetaLine(
              label: 'Capacity',
              value: residence.capacityLabel,
            ),
            _MetaLine(
              label: 'Assigned Staff',
              value: residence.assignedStaffLabel,
            ),
            _MetaLine(
              label: 'Primary Manager',
              value: residence.primaryManager?.name ?? '—',
            ),
            _MetaLine(
              label: 'GPS Radius',
              value: residence.gpsRadiusLabel,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.dividerLight),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Actions',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                _ActionIconButton(
                  key: Key('staff-residence-view-${residence.id}'),
                  tooltip: 'View',
                  icon: Icons.visibility_outlined,
                  color: AppColors.secondaryTeal,
                  onTap: onView,
                ),
                if (onEdit != null)
                  _ActionIconButton(
                    key: Key('staff-residence-edit-${residence.id}'),
                    tooltip: 'Edit',
                    icon: Icons.edit_outlined,
                    color: AppColors.textSecondary,
                    onTap: onEdit,
                  ),
                if (onDeactivate != null)
                  _ActionIconButton(
                    key: Key('staff-residence-deactivate-${residence.id}'),
                    tooltip: residence.isActive ? 'Deactivate' : 'Archived',
                    icon: Icons.do_not_disturb_on_outlined,
                    color: residence.isActive
                        ? AppColors.criticalRed
                        : AppColors.textMuted,
                    onTap: residence.isActive ? onDeactivate : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Icon(
                icon,
                size: 18,
                color: enabled ? color : AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;
  final String? secondary;

  const _MetaLine({
    required this.label,
    required this.value,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveHelper.getResponsiveWidth(context, 108),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textHeading,
                    height: 1.25,
                  ),
                ),
                if ((secondary ?? '').isNotEmpty)
                  Text(
                    secondary!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
