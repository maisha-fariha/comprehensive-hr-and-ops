import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/authorized_file.dart';
import '../../domain/entities/attendance_record.dart';
import '../attendance_formatters.dart';

enum AttendanceTone { success, warning, danger, info, neutral }

extension AttendanceToneColors on AttendanceTone {
  Color get foreground => switch (this) {
        AttendanceTone.success => AppColors.activeGreen,
        AttendanceTone.warning => AppColors.urgentAmber,
        AttendanceTone.danger => AppColors.criticalRed,
        AttendanceTone.info => AppColors.infoBlue,
        AttendanceTone.neutral => AppColors.textSecondary,
      };

  Color get background => switch (this) {
        AttendanceTone.success => AppColors.activeBackground,
        AttendanceTone.warning => AppColors.urgentBackground,
        AttendanceTone.danger => AppColors.criticalBackgroundSoft,
        AttendanceTone.info => AppColors.infoBackground,
        AttendanceTone.neutral => AppColors.filterButtonBackground,
      };
}

AttendanceTone statusTone(String status) => switch (status) {
      'present' => AttendanceTone.success,
      'late' => AttendanceTone.warning,
      'missed' => AttendanceTone.danger,
      'pending_approval' => AttendanceTone.info,
      _ => AttendanceTone.neutral,
    };

class AttendancePill extends StatelessWidget {
  final String label;
  final AttendanceTone tone;
  final bool dot;

  const AttendancePill({
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
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// One web table row laid out as a card: Staff, Date, In / Out, Worked,
/// Where & photo, Status and the manager actions.
class AttendanceRecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final bool canManage;
  final bool busy;
  final VoidCallback? onCorrect;
  final VoidCallback? onDelete;
  final VoidCallback? onReject;
  final VoidCallback? onApprove;

  const AttendanceRecordCard({
    super.key,
    required this.record,
    required this.canManage,
    this.busy = false,
    this.onCorrect,
    this.onDelete,
    this.onReject,
    this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final exception = AttendanceFormat.exceptionLine(record);
    final whereTone = switch (record.checkIn.geofenceStatus) {
      'inside' => AttendanceTone.success,
      'outside' => AttendanceTone.danger,
      _ => AttendanceTone.neutral,
    };
    final selfie = record.checkIn.selfieUrl;

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
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
                      record.staffName,
                      style: _style(context, 14.5, FontWeight.w600,
                          AppColors.primaryNavy),
                    ),
                    Text(
                      record.residenceName.isEmpty ? '—' : record.residenceName,
                      style: _style(context, 12, FontWeight.w400,
                          AppColors.infoBlue),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: [
                  AttendancePill(
                    label: AttendanceFormat.humanise(record.status),
                    tone: statusTone(record.status),
                    dot: true,
                  ),
                  if (record.isManual)
                    const AttendancePill(
                      label: 'Manual',
                      tone: AttendanceTone.neutral,
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Column(
                label: 'Date',
                value: AttendanceFormat.date(record.checkInAt),
              ),
              _Column(
                label: 'In / Out',
                value: AttendanceFormat.inOut(record),
                flex: 3,
              ),
              _Column(
                label: 'Worked',
                value: AttendanceFormat.worked(record.workedMinutes),
                detail: record.breakMinutes > 0
                    ? '${record.breakMinutes}m break'
                    : null,
                flex: 2,
              ),
            ],
          ),
          if (exception != null) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
            Text(
              exception,
              style: _style(context, 11, FontWeight.w600, AppColors.criticalRed),
            ),
          ],
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Row(
            children: [
              AttendancePill(
                label: AttendanceFormat.where(record.checkIn),
                tone: whereTone,
              ),
              if (selfie != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showPhoto(context, selfie),
                  child: Text(
                    'Photo',
                    style: _style(context, 12, FontWeight.w500,
                        AppColors.infoBlue),
                  ),
                ),
              ],
            ],
          ),
          if (canManage) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                _ActionButton(
                  key: ValueKey('attendance-correct-${record.id}'),
                  label: 'Correct',
                  onTap: busy ? null : onCorrect,
                ),
                _ActionButton(
                  key: ValueKey('attendance-delete-${record.id}'),
                  icon: Icons.delete_outline_rounded,
                  semanticLabel: 'Delete record',
                  foreground: AppColors.criticalRed,
                  onTap: busy ? null : onDelete,
                ),
                if (record.needsApproval) ...[
                  _ActionButton(
                    key: ValueKey('attendance-reject-${record.id}'),
                    label: 'Reject',
                    onTap: busy ? null : onReject,
                  ),
                  _ActionButton(
                    key: ValueKey('attendance-approve-${record.id}'),
                    label: 'Approve',
                    filled: true,
                    onTap: busy ? null : onApprove,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              AuthorizedFile.resolveUrl(url),
              headers: AuthorizedFile.headers(),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('The photo could not be loaded.'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _style(
  BuildContext context,
  double size,
  FontWeight weight,
  Color color,
) =>
    TextStyle(
      fontFamily: 'Outfit',
      fontWeight: weight,
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, size),
      color: color,
    );

class _Column extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final int flex;

  const _Column({
    required this.label,
    required this.value,
    this.detail,
    this.flex = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _style(context, 11, FontWeight.w600, AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: _style(context, 13, FontWeight.w500, AppColors.textHeading),
          ),
          if (detail != null)
            Text(
              detail!,
              style: _style(context, 11.5, FontWeight.w400, AppColors.infoBlue),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final bool filled;
  final Color? foreground;
  final VoidCallback? onTap;

  const _ActionButton({
    super.key,
    this.label,
    this.icon,
    this.semanticLabel,
    this.filled = false,
    this.foreground,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = filled
        ? Colors.white
        : (foreground ?? AppColors.textHeading);
    final radius = BorderRadius.circular(
      ResponsiveHelper.getResponsiveRadius(context, 8),
    );
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: filled ? AppColors.primaryNavy : AppColors.surfaceWhite,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: ResponsiveHelper.getResponsiveHeight(context, 32),
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: icon != null && label == null ? 9 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: filled ? null : Border.all(color: AppColors.searchBorder),
            ),
            child: Align(
              widthFactor: 1,
              child: icon != null && label == null
                  ? Icon(
                      icon,
                      size: ResponsiveHelper.getResponsiveSize(context, 15),
                      color: color,
                      semanticLabel: semanticLabel,
                    )
                  : Text(
                      label ?? '',
                      style: _style(context, 12.5, FontWeight.w600, color),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
