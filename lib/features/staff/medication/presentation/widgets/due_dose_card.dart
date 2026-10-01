import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/due_dose.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../staff_medication_constants.dart';
import 'status_by_row.dart';

/// A single dose card in the "Due" tab (Due Now / Later Today).
class DueDoseCard extends StatelessWidget {
  final DueDose dose;
  final VoidCallback onAdminister;
  final VoidCallback onNotGiven;
  final VoidCallback? onOpenClientMedications;
  final bool canWrite;

  /// Web "Edit prescription" (`mar:write`).
  final VoidCallback? onEdit;

  /// Who signed a charted dose (footer "by …").
  final String administeredByName;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _metaColor = Color(0xFF7E8B9A);
  static const Color _accentGreen = Color(0xFF2D8A56);
  static const Color _notGivenBorder = Color(0xFFE5E9EF);

  const DueDoseCard({
    super.key,
    required this.dose,
    required this.onAdminister,
    required this.onNotGiven,
    this.onOpenClientMedications,
    this.canWrite = true,
    this.onEdit,
    this.administeredByName = 'you',
  });

  static const Map<String, String> _stateLabels = {
    'given': 'Given',
    'late': 'Given late',
    'due': 'Due now',
    'upcoming': 'Upcoming',
    'overdue': 'Overdue',
    'missed': 'Missed',
    'refused': 'Refused',
    'withheld': 'Withheld',
    'not_available': 'Not available',
  };

  String get _stateLabel => _stateLabels[dose.state] ?? dose.state;

  ({Color fg, Color bg}) get _stateTone => switch (dose.state) {
        'given' => (fg: AppColors.activeGreen, bg: AppColors.activeBackground),
        'late' ||
        'refused' =>
          (fg: AppColors.urgentAmber, bg: AppColors.urgentBackground),
        'due' ||
        'withheld' =>
          (fg: AppColors.infoBlue, bg: AppColors.infoBackground),
        'overdue' ||
        'missed' ||
        'not_available' =>
          (fg: AppColors.criticalRed, bg: AppColors.criticalBackgroundSoft),
        _ => (
            fg: AppColors.textSecondary,
            bg: AppColors.filterButtonBackground,
          ),
      };

  String get _routeLabel =>
      StaffMedicationConstants.routeLabel(dose.route).replaceAll(' · ', '  •  ');

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final avatarStyle = StaffMedicationConstants.avatarStyle(dose.avatarColor);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onOpenClientMedications,
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: avatarStyle.background,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dose.residentInitials,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: avatarStyle.foreground,
                      height: 1,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dose.residentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            14,
                          ),
                          color: _titleColor,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 3),
                      ),
                      Text(
                        '${dose.medicationName} ${dose.dose}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            14,
                          ),
                          color: _titleColor,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 3),
                      ),
                      Text(
                        dose.isPrn ? 'PRN  •  $_routeLabel' : _routeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12.5,
                          ),
                          color: _metaColor,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dose.slotLabel.isNotEmpty)
                      Text(
                        dose.slotLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            11.5,
                          ),
                          color: _metaColor,
                          height: 1.2,
                        ),
                      ),
                    Text(
                      dose.timeLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 13),
                        color: _accentGreen,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                    ),
                    Container(
                      key: ValueKey('staff-mar-state-${dose.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _stateTone.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _stateLabel.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            10.5,
                          ),
                          color: _stateTone.fg,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (dose.residenceName.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            Text(
              dose.residenceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: _metaColor,
              ),
            ),
          ],
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          _buildActionArea(context),
          if (onEdit != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: ValueKey('staff-mar-edit-${dose.id}'),
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondaryTeal,
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'Edit prescription',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context) {
    switch (dose.status) {
      case DueDoseStatus.upcoming:
      case DueDoseStatus.pending:
        if (!canWrite) {
          return Text(
            dose.isPrn
                ? 'View only — PRN needs medication-admin certification.'
                : 'View only — administering needs mar:write permission.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: _metaColor,
            ),
          );
        }
        return Row(
          children: [
            Expanded(child: _AdministerButton(onTap: onAdminister)),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(child: _NotGivenButton(onTap: onNotGiven)),
          ],
        );
      case DueDoseStatus.administered:
        return StatusByRow(
          label: _stateLabels.containsKey(dose.state)
              ? _stateLabel
              : 'Administered',
          byName: administeredByName,
          background: AppColors.activeBackground,
          foreground: AppColors.activeGreen,
          svgAsset: AppAssets.checkCircle,
        );
      case DueDoseStatus.notGiven:
        return StatusByRow(
          label: _stateLabels.containsKey(dose.state) ? _stateLabel : 'Not Given',
          byName: administeredByName,
          background: AppColors.criticalBackground,
          foreground: AppColors.criticalRed,
          materialIcon: Icons.cancel_rounded,
        );
    }
  }
}

class _AdministerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AdministerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          height: ResponsiveHelper.getResponsiveHeight(context, 44),
          decoration: BoxDecoration(
            color: DueDoseCard._accentGreen,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                'assets/icons/staff_medication/check.svg',
                size: ResponsiveHelper.getResponsiveSize(context, 16),
                color: Colors.white,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                'Administer',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotGivenButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NotGivenButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          height: ResponsiveHelper.getResponsiveHeight(context, 44),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: DueDoseCard._notGivenBorder),
          ),
          child: Center(
            child: Text(
              'Not Given',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: DueDoseCard._titleColor,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
